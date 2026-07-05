import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/field_models.dart';

class FieldService {
  final supabase = Supabase.instance.client;
  static const _storageKey = 'field_service_field_grids';

  Future<FieldGrid> createGrid({
    required String organizationId,
    required String gridCode,
    String? state,
    String? district,
    String? mandal,
    String? village,
    String? createdBy,
  }) async {
    try {
      final grid = FieldGrid(
        organizationId: organizationId,
        gridCode: gridCode,
        state: state,
        district: district,
        mandal: mandal,
        village: village,
        createdBy: createdBy,
      );

      final response =
          await supabase.from('field_grids').insert(grid.toMap()).select();

      final createdGrid = FieldGrid.fromMap(response[0]);
      await _persistGridLocally(createdGrid);
      return createdGrid;
    } catch (e) {
      print('Error creating grid: $e');
      final fallbackGrid = FieldGrid(
        organizationId: organizationId,
        gridCode: gridCode,
        state: state,
        district: district,
        mandal: mandal,
        village: village,
        createdBy: createdBy,
      );
      await _persistGridLocally(fallbackGrid);
      return fallbackGrid;
    }
  }

  Future<List<FieldGrid>> getGrids({
    required String organizationId,
  }) async {
    try {
      final response = await supabase
          .from('field_grids')
          .select()
          .eq('organization_id', organizationId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final grids = response.map((map) => FieldGrid.fromMap(map)).toList();
      await _persistGridsLocally(grids);
      return grids;
    } catch (e) {
      print('Error fetching grids: $e');
      return _loadGridsLocally(organizationId);
    }
  }

  Future<Family> registerFamily({
    required String gridId,
    required String organizationId,
    required String familyHeadName,
    String? address,
  }) async {
    try {
      final familyId = _generateFamilyId();

      final family = Family(
        gridId: gridId,
        organizationId: organizationId,
        familyId: familyId,
        familyHeadName: familyHeadName,
        address: address,
      );

      final response =
          await supabase.from('families').insert(family.toMap()).select();

      return Family.fromMap(response[0]);
    } catch (e) {
      print('Error registering family: $e');
      rethrow;
    }
  }

  Future<FamilyMember> addFamilyMember({
    required String familyId,
    required String organizationId,
    required String fullName,
    DateTime? dob,
    String? gender,
    String? relation,
    String? masterBeneficiaryId,
  }) async {
    try {
      final member = FamilyMember(
        familyId: familyId,
        organizationId: organizationId,
        fullName: fullName,
        dob: dob,
        gender: gender,
        relation: relation,
        masterBeneficiaryId: masterBeneficiaryId,
      );

      final response = await supabase
          .from('family_members')
          .insert(member.toMap())
          .select();

      return FamilyMember.fromMap(response[0]);
    } catch (e) {
      print('Error adding family member: $e');
      rethrow;
    }
  }

  Future<List<Family>> getFamilies({
    required String gridId,
  }) async {
    try {
      final response = await supabase
          .from('families')
          .select()
          .eq('grid_id', gridId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return response.map((map) => Family.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching families: $e');
      return [];
    }
  }

  Future<List<FamilyMember>> getFamilyMembers({
    required String familyId,
  }) async {
    try {
      final response = await supabase
          .from('family_members')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: true);

      return response.map((map) => FamilyMember.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching family members: $e');
      return [];
    }
  }

  Future<FamilyMember?> getFamilyMember({
    required String memberId,
  }) async {
    try {
      final response = await supabase
          .from('family_members')
          .select()
          .eq('id', memberId)
          .single();

      return FamilyMember.fromMap(response);
    } catch (e) {
      print('Error fetching family member: $e');
      return null;
    }
  }

  Future<void> updateFamilyMember({
    required String memberId,
    String? fullName,
    DateTime? dob,
    String? gender,
    String? relation,
    String? masterBeneficiaryId,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (dob != null) updates['dob'] = dob.toIso8601String();
      if (gender != null) updates['gender'] = gender;
      if (relation != null) updates['relation'] = relation;
      if (masterBeneficiaryId != null) {
        updates['master_beneficiary_id'] = masterBeneficiaryId;
      }
      updates['updated_at'] = DateTime.now().toIso8601String();

      await supabase.from('family_members').update(updates).eq('id', memberId);
    } catch (e) {
      print('Error updating family member: $e');
      rethrow;
    }
  }

  Future<int> getFamilyCount({
    required String gridId,
  }) async {
    try {
      final response = await supabase
          .from('families')
          .select('count')
          .eq('grid_id', gridId)
          .eq('status', 'active')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      print('Error getting family count: $e');
      return 0;
    }
  }

  Future<int> getTotalMembers({
    required String organizationId,
  }) async {
    try {
      final response = await supabase
          .from('family_members')
          .select('count')
          .eq('organization_id', organizationId)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      print('Error getting member count: $e');
      return 0;
    }
  }

  Future<void> _persistGridLocally(FieldGrid grid) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await _loadStoredGrids();
    final updated = <String, Map<String, dynamic>>{};

    for (final item in existing) {
      updated[item.id] = item.toMap();
    }

    updated[grid.id] = grid.toMap();

    final payload = updated.values
        .map((map) => jsonEncode(map))
        .toList(growable: false);

    await prefs.setStringList(_storageKey, payload);
  }

  Future<void> _persistGridsLocally(List<FieldGrid> grids) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String>{};

    for (final grid in grids) {
      payload.add(jsonEncode(grid.toMap()));
    }

    await prefs.setStringList(_storageKey, payload.toList());
  }

  Future<List<FieldGrid>> _loadStoredGrids() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];

    return raw
        .where((entry) => entry.isNotEmpty)
        .map((entry) => FieldGrid.fromMap(jsonDecode(entry) as Map<String, dynamic>))
        .toList();
  }

  Future<List<FieldGrid>> _loadGridsLocally(String organizationId) async {
    final grids = await _loadStoredGrids();
    final filtered = grids
        .where((grid) => grid.organizationId == organizationId)
        .toList();

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  String _generateFamilyId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'FAM-$timestamp-$random';
  }
}
