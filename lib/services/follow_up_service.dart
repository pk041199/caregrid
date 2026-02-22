import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

class FollowUpService {
  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _authService = AuthService();

  Future<List<Map<String, String>>> fetchPlannedFollowUps({
    required String areaCode,
    required String samplingUnit,
  }) async {
    final orgId = _authService.currentSession?.organizationId ?? '';

    final rpcRows = await _fetchByRpc(
      organizationId: orgId,
      areaCode: areaCode,
      samplingUnit: samplingUnit,
    );
    if (rpcRows.isNotEmpty) {
      return _normalizeRows(rpcRows);
    }

    final tableRows = await _fetchByTableFallback(
      organizationId: orgId,
      areaCode: areaCode,
      samplingUnit: samplingUnit,
    );
    return _normalizeRows(tableRows);
  }

  Future<List<Map<String, dynamic>>> _fetchByRpc({
    required String organizationId,
    required String areaCode,
    required String samplingUnit,
  }) async {
    final attempts = <({String fn, Map<String, dynamic> params})>[
      (
        fn: 'get_follow_up_dashboard_v1',
        params: {
          'p_org_id': organizationId,
          'p_area_code': areaCode,
          'p_sampling_unit': samplingUnit,
        }
      ),
      (
        fn: 'get_follow_up_dashboard_v1',
        params: {
          'org_id': organizationId,
          'area_code': areaCode,
          'sampling_unit': samplingUnit,
        }
      ),
    ];

    for (final attempt in attempts) {
      try {
        final response = await _client.rpc(attempt.fn, params: attempt.params);
        if (response is List) {
          return response
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } on PostgrestException {
        // Try next attempt.
      } catch (_) {
        // Try next attempt.
      }
    }

    return const <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> _fetchByTableFallback({
    required String organizationId,
    required String areaCode,
    required String samplingUnit,
  }) async {
    const candidateTables = <String>[
      'follow_up_plans',
      'revisit_plans',
      'follow_ups',
    ];

    for (final table in candidateTables) {
      try {
        final response = await _client.from(table).select().limit(500);
        final rows = response
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        return rows.where((row) {
          final rowOrg = _firstNonEmptyString(row, const [
            'organization_id',
            'org_id',
          ]);
          final rowArea = _firstNonEmptyString(row, const [
            'area_code',
            'grid_code',
          ]);
          final rowSampling = _firstNonEmptyString(row, const [
            'sampling_unit',
          ]);

          final orgMatches = organizationId.isEmpty || rowOrg == organizationId;
          final areaMatches = areaCode.isEmpty || rowArea == areaCode;
          final samplingMatches =
              samplingUnit.isEmpty || rowSampling.toLowerCase() == samplingUnit.toLowerCase();

          return orgMatches && areaMatches && samplingMatches;
        }).toList();
      } on PostgrestException {
        // Try next table.
      } catch (_) {
        // Try next table.
      }
    }

    return const <Map<String, dynamic>>[];
  }

  List<Map<String, String>> _normalizeRows(List<Map<String, dynamic>> rows) {
    return rows.map((row) {
      final formId = _firstNonEmptyString(row, const [
        'form_id',
        'form',
        'module_id',
      ]);
      final formCategory = _firstNonEmptyString(row, const [
        'form_category',
        'category',
      ]);
      final normalizedCategory = formCategory.isNotEmpty
          ? formCategory
          : (formId == 'under_5'
              ? 'Under-5'
              : formId == 'new_born'
                  ? 'New Born'
                  : formId.toUpperCase());

      final memberName = _firstNonEmptyString(row, const [
        'member_name',
        'person_name',
        'full_name',
      ]);
      final scope = _firstNonEmptyString(row, const [
        'scope',
        'follow_up_scope',
      ]);
      return {
        'familyId': _firstNonEmptyString(row, const [
          'family_id',
          'family_code',
        ]),
        'memberName': memberName,
        'formId': formId,
        'formTitle': _firstNonEmptyString(row, const [
          'form_title',
          'title',
          'form_name',
        ]),
        'formCategory': normalizedCategory,
        'followUpDate': _firstNonEmptyString(row, const [
          'follow_up_date',
          'next_visit_date',
          'followup_date',
        ]),
        'status': _firstNonEmptyString(row, const [
          'status',
          'follow_up_status',
          'plan_status',
        ]).isEmpty
            ? 'Planned'
            : _firstNonEmptyString(row, const [
                'status',
                'follow_up_status',
                'plan_status',
              ]),
        'scope': scope.isNotEmpty
            ? scope
            : (memberName.toLowerCase() == 'family' || memberName.isEmpty
                ? 'Family'
                : 'Individual'),
      };
    }).where((row) => (row['followUpDate'] ?? '').trim().isNotEmpty).toList();
  }

  String _firstNonEmptyString(
    Map<String, dynamic> row,
    List<String> candidates,
  ) {
    for (final key in candidates) {
      final value = row[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}
