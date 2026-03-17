import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'form_viewer_screen.dart';
import '../services/follow_up_service.dart';
import '../services/auth_service.dart';
import '../services/medical_role_policy.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  bool _loading = true;
  String? _error;
  final List<_DoctorCase> _cases = [];
  final FollowUpService _followUpService = FollowUpService();
  final AuthService _authService = AuthService();
  String _roleLabel = '';
  bool _canReview = false;

  @override
  void initState() {
    super.initState();
    final role = _authService.currentUserRole;
    _roleLabel = MedicalRolePolicy.label(role);
    _canReview = MedicalRolePolicy.canReviewClinical(role);
    _loadCases();
  }

  Future<void> _loadCases() async {
    setState(() {
      _loading = true;
      _error = null;
      _cases.clear();
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('caregrid_') && k.endsWith('_families'));
      for (final key in keys) {
        final raw = prefs.getString(key) ?? '';
        if (raw.trim().isEmpty) continue;
        final decoded = jsonDecode(raw);
        if (decoded is! List) continue;
        for (final familyRaw in decoded) {
          if (familyRaw is! Map) continue;
          final family = familyRaw.map((k, v) => MapEntry(k.toString(), v));
          final familyId = (family['familyId'] ?? '').toString();
          final members = family['members'];
          if (members is! List) continue;
          for (final memberRaw in members) {
            if (memberRaw is! Map) continue;
            final member = memberRaw.map((k, v) => MapEntry(k.toString(), (v ?? '').toString()));
            final hasNcd = (member['hasNcd'] ?? '').toLowerCase() == 'yes' ||
                (member['ncdActive'] ?? '').toLowerCase() == 'true';
            final historyRaw = (member['clinicalHistoryNcdEntries'] ?? '').trim();
            final history = _decodeHistory(historyRaw);
            if (!hasNcd && history.isEmpty) continue;
            _cases.add(
              _DoctorCase(
                storageKey: key,
                familyId: familyId,
                memberName: member['fullName'] ?? '',
                memberPersonUuid: member['personUuid'] ?? '',
                history: history,
              ),
            );
          }
        }
      }
      _cases.sort((a, b) {
        final ad = _latestDate(a.history);
        final bd = _latestDate(b.history);
        return bd.compareTo(ad);
      });
    } catch (e) {
      _error = 'Failed to load doctor cases: $e';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> _decodeHistory(String raw) {
    if (raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  DateTime _latestDate(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    DateTime best = DateTime.fromMillisecondsSinceEpoch(0);
    for (final entry in history) {
      final raw = (entry['submittedAt'] ?? entry['followUpDate'] ?? '').toString();
      final parsed = DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (parsed.isAfter(best)) best = parsed;
    }
    return best;
  }

  String _latestSummary(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return 'No prior NCD clinical entry';
    final latest = history.last;
    final values = latest['values'];
    if (values is! Map) return 'Previous entry available';
    final complaintsRaw = (values['chief_complaints'] ?? '').toString();
    try {
      final decoded = jsonDecode(complaintsRaw);
      if (decoded is List && decoded.isNotEmpty) {
        final names = decoded
            .whereType<Map>()
            .map((e) => (e['complaint'] ?? '').toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (names.isNotEmpty) {
          return names.join(', ');
        }
      }
    } catch (_) {}
    return 'Previous entry available';
  }

  Future<void> _openDoctorReview(_DoctorCase c) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormViewerScreen(
          assetPath: 'assets/forms/clinical_history_ncd.json',
          entityLabel: '${c.memberName} (${c.familyId})',
          contextData: {
            'previousEntries': c.history,
          },
        ),
      ),
    );
    if (result is! Map<String, dynamic>) return;
    await _appendDoctorResult(c, result);
    await _upsertDoctorReview(c, result);
    if (!mounted) return;
    _showPrescriptionDialog(c, result);
    await _loadCases();
  }

  Future<void> _appendDoctorResult(_DoctorCase c, Map<String, dynamic> result) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(c.storageKey) ?? '';
    if (raw.trim().isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return;
    bool changed = false;
    for (final familyRaw in decoded) {
      if (familyRaw is! Map) continue;
      final family = familyRaw;
      final familyId = (family['familyId'] ?? '').toString();
      if (familyId != c.familyId) continue;
      final members = family['members'];
      if (members is! List) continue;
      for (final memberRaw in members) {
        if (memberRaw is! Map) continue;
        final member = memberRaw;
        final personUuid = (member['personUuid'] ?? '').toString();
        final fullName = (member['fullName'] ?? '').toString();
        final matches = (c.memberPersonUuid.isNotEmpty && c.memberPersonUuid == personUuid) ||
            (c.memberPersonUuid.isEmpty && fullName == c.memberName);
        if (!matches) continue;
        final history = _decodeHistory((member['clinicalHistoryNcdEntries'] ?? '').toString());
        history.add(result);
        member['clinicalHistoryNcdEntries'] = jsonEncode(history);
        final followDate = (result['followUpDate'] ?? '').toString().trim();
        if (followDate.isNotEmpty) {
          member['nextFollowUpDate'] = followDate;
        }
        changed = true;
        break;
      }
      if (changed) break;
    }
    if (changed) {
      await prefs.setString(c.storageKey, jsonEncode(decoded));
      await _markLocalRevisitDoctorReviewed(c, result);
    }
  }

  Future<void> _markLocalRevisitDoctorReviewed(
    _DoctorCase c,
    Map<String, dynamic> result,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final revisitKey = c.storageKey.replaceAll('_families', '_revisits');
    final raw = prefs.getString(revisitKey) ?? '';
    if (raw.trim().isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return;
    bool changed = false;
    final newFollow = (result['followUpDate'] ?? '').toString().trim();
    final reviewedBy =
        _authService.currentUserName ?? _authService.currentSession?.userId ?? '';
    final reviewedAt = DateTime.now().toIso8601String();
    for (final rowRaw in decoded) {
      if (rowRaw is! Map) continue;
      final row = rowRaw;
      final rowFamily = (row['familyId'] ?? '').toString();
      final rowMember = (row['memberName'] ?? '').toString();
      final rowForm = (row['formId'] ?? '').toString();
      if (rowFamily != c.familyId || rowMember != c.memberName) continue;
      if (rowForm != 'clinical_history_ncd' && rowForm != 'ncd') continue;
      row['status'] = 'Doctor Reviewed';
      row['reviewedBy'] = reviewedBy;
      row['reviewedAt'] = reviewedAt;
      if (newFollow.isNotEmpty) {
        row['followUpDate'] = newFollow;
      }
      changed = true;
    }
    if (changed) {
      await prefs.setString(revisitKey, jsonEncode(decoded));
    }
  }

  String _buildPrescription(_DoctorCase c, Map<String, dynamic> result) {
    final values = result['values'] is Map
        ? (result['values'] as Map).map((k, v) => MapEntry(k.toString(), v))
        : <String, dynamic>{};
    final includeSameDay =
        (values['include_same_day_in_final_treatment'] ?? 'Yes').toString() == 'Yes';
    final sameDayTreat =
        includeSameDay ? _decodeStringList(values['same_day_treatments_readonly']) : <String>[];
    final sameDayInv = includeSameDay
        ? _decodeStringList(values['same_day_investigations_readonly'])
        : <String>[];
    final investigations = <String>[
      ...sameDayInv,
      ..._decodeStringList(values['investigations_to_do']),
      ..._decodeGroupRows(
        values['additional_investigations'],
        const ['investigation', 'frequency', 'period'],
      ),
    ];
    final treatments = <String>[
      ...sameDayTreat,
      ..._decodeGroupRows(
        values['additional_treatments'],
        const ['medication', 'dose', 'frequency', 'period'],
      ),
      (values['overall_treatment_plan'] ?? '').toString().trim(),
      (values['treatment_plan'] ?? '').toString().trim(),
      (values['prescription_details'] ?? '').toString().trim(),
    ].where((e) => e.isNotEmpty).toList();
    final doctorNotes = (values['doctor_notes'] ?? '').toString().trim();
    final finalAdvice = (values['final_notes_advice'] ?? '').toString().trim();
    final diagnosis = (values['working_diagnosis'] ?? '').toString().trim();
    final followUpDate = (result['followUpDate'] ?? values['follow_up_date'] ?? '').toString().trim();
    final lines = <String>[
      'CAREGRID PRESCRIPTION',
      '--------------------',
      'Date: ${DateTime.now().toIso8601String().split('T').first}',
      'Patient: ${c.memberName}',
      'Family ID: ${c.familyId}',
      '',
      'Investigations:',
      if (investigations.isEmpty) '- None specified',
      ...investigations.map((e) => '- $e'),
      '',
      'Treatment / Advice:',
      if (treatments.isEmpty) '- Not specified',
      ...treatments.map((e) => '- $e'),
      '',
      'Diagnosis:',
      diagnosis.isEmpty ? '- Not specified' : diagnosis,
      '',
      'Final Notes / Advice:',
      finalAdvice.isEmpty ? '- None' : finalAdvice,
      '',
      'Doctor Notes:',
      doctorNotes.isEmpty ? '- None' : doctorNotes,
      '',
      'Follow-up Date: ${followUpDate.isEmpty ? '-' : followUpDate}',
    ];
    return lines.join('\n');
  }

  List<String> _decodeGroupRows(dynamic raw, List<String> keys) {
    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return const [];
    try {
      final parsed = jsonDecode(text);
      if (parsed is! List) return const [];
      final rows = <String>[];
      for (final item in parsed) {
        if (item is! Map) continue;
        final map = item.map((k, v) => MapEntry(k.toString(), (v ?? '').toString()));
        final chunks = <String>[];
        for (final k in keys) {
          final val = (map[k] ?? '').trim();
          if (val.isNotEmpty) chunks.add(val);
        }
        if (chunks.isNotEmpty) rows.add(chunks.join(' | '));
      }
      return rows;
    } catch (_) {
      return const [];
    }
  }

  List<String> _decodeStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return const [];
    try {
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
      }
    } catch (_) {}
    return text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> _showPrescriptionDialog(
    _DoctorCase c,
    Map<String, dynamic> result,
  ) async {
    final text = _buildPrescription(c, result);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Prescription Generator'),
          content: SingleChildScrollView(
            child: SelectableText(text),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _printPrescriptionPdf(c, text);
              },
              child: const Text('PDF'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Prescription copied')),
                );
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printPrescriptionPdf(_DoctorCase c, String text) async {
    final doctorName = _authService.currentUserName ?? 'Doctor';
    final today = DateTime.now().toIso8601String().split('T').first;
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CareGrid Prescription',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Patient: ${c.memberName}'),
                pw.Text('Family ID: ${c.familyId}'),
                pw.Text('Date: $today'),
                pw.SizedBox(height: 12),
                pw.Text(text),
                pw.Spacer(),
                pw.Divider(),
                pw.SizedBox(height: 6),
                pw.Text('Doctor Signature: __________________________'),
                pw.Text('Doctor Name: $doctorName'),
              ],
            ),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  Future<void> _upsertDoctorReview(
    _DoctorCase c,
    Map<String, dynamic> result,
  ) async {
    final values = result['values'] is Map
        ? (result['values'] as Map).map((k, v) => MapEntry(k.toString(), v))
        : <String, dynamic>{};
    final followUpDate = (result['followUpDate'] ?? values['follow_up_date'] ?? '')
        .toString()
        .trim();
    final investigations = _decodeStringList(values['investigations_to_do']);
    final treatment = (values['treatment_plan'] ?? '').toString().trim();
    final doctorNotes = (values['doctor_notes'] ?? '').toString().trim();
    try {
      await _followUpService.upsertDoctorReview(
        familyId: c.familyId,
        memberName: c.memberName,
        formId: 'clinical_history_ncd',
        followUpDate: followUpDate,
        status: 'Doctor Reviewed',
        doctorNotes: doctorNotes,
        treatmentPlan: treatment,
        investigations: investigations,
        scope: 'Individual',
      );
    } catch (_) {
      // Keep local flow functional even if remote write fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            onPressed: _loadCases,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: !_canReview
            ? const Center(
                child: Text('Access denied. Doctor/Curator/Manager role required.'),
              )
            : _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _cases.isEmpty
                    ? const Center(
                        child: Text('No NCD follow-up cases available from field entries.'),
                      )
                    : ListView.separated(
                        itemCount: _cases.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final c = _cases[index];
                          final latestDate = _latestDate(c.history);
                          return Card(
                            child: ListTile(
                            title: Text('${c.memberName} | Family ${c.familyId}'),
                            subtitle: Text(
                                'Role: $_roleLabel\n'
                                'Last update: ${latestDate == DateTime.fromMillisecondsSinceEpoch(0) ? '-' : latestDate.toIso8601String().split('T').first}\n'
                                'Latest: ${_latestSummary(c.history)}',
                              ),
                              isThreeLine: true,
                              trailing: ElevatedButton.icon(
                                onPressed: () => _openDoctorReview(c),
                                icon: const Icon(Icons.medical_services_outlined),
                                label: const Text('Review'),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _DoctorCase {
  const _DoctorCase({
    required this.storageKey,
    required this.familyId,
    required this.memberName,
    required this.memberPersonUuid,
    required this.history,
  });

  final String storageKey;
  final String familyId;
  final String memberName;
  final String memberPersonUuid;
  final List<Map<String, dynamic>> history;
}
