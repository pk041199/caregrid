import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'form_viewer_screen.dart';
import 'follow_up_dashboard_screen.dart';
import 'individual_data_collection_screen.dart';
import 'individual_profile_screen.dart';
import 'widgets/data_collection_widgets.dart';
import '../services/auth_service.dart';
import 'id_card_screen.dart';

import '../services/sync_service.dart';

class DataCollectionScreen extends StatefulWidget {
  const DataCollectionScreen({
    super.key,
    required this.samplingUnit,
    required this.setupData,
  });

  final String samplingUnit;
  final Map<String, String> setupData;

  @override
  State<DataCollectionScreen> createState() => _DataCollectionScreenState();
}

class _DataCollectionScreenState extends State<DataCollectionScreen> {
  final GlobalKey<DataCollectionSectionState> _sectionKey =
      GlobalKey<DataCollectionSectionState>();

  @override
  Widget build(BuildContext context) {
    if (widget.samplingUnit == 'Individual') {
      return IndividualDataCollectionScreen(
        samplingUnit: widget.samplingUnit,
        setupData: widget.setupData,
      );
    }
    if (widget.samplingUnit == 'Community') {
      return Scaffold(
        appBar: AppBar(title: const Text('Data Collection')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Community data collection workflow is under development.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Collection'),
        actions: [
          IconButton(
            onPressed: _openFollowUpDashboard,
            icon: const Icon(Icons.event_note_outlined),
            tooltip: 'Follow-ups',
          ),
          IconButton(
            onPressed: () async {
              final state = _sectionKey.currentState;
              if (state == null) return;
              await state.uploadEntries();
            },
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Upload',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: DataCollectionSection(
              key: _sectionKey,
              samplingUnit: widget.samplingUnit,
              setupData: widget.setupData,
            ),
          ),
        ],
      ),
    );
  }

  void _openFollowUpDashboard() {
    final state = _sectionKey.currentState;
    final entries = state?.getRevisitEntries() ?? const <Map<String, String>>[];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowUpDashboardScreen(
          entries: entries,
          samplingUnit: widget.samplingUnit,
          setupData: widget.setupData,
          onEntriesChanged: (updated) {
            _sectionKey.currentState?.replaceRevisitEntries(updated);
          },
          onOpenFollowUpForm: (row) async {
            final handler = _sectionKey.currentState;
            if (handler == null) return false;
            return handler.openFollowUpFromDashboard(row);
          },
        ),
      ),
    );
  }
}

class DataCollectionSection extends StatefulWidget {
  const DataCollectionSection({
    super.key,
    required this.samplingUnit,
    required this.setupData,
    this.filterWidget,
    this.revisitFilter = 'All',
  });

  final String samplingUnit;
  final Map<String, String> setupData;
  final Widget? filterWidget;
  final String revisitFilter;

  @override
  State<DataCollectionSection> createState() => DataCollectionSectionState();
}

class DataCollectionSectionState extends State<DataCollectionSection> {
  final SyncService _syncService = SyncService();
  final List<Map<String, dynamic>> _familyEntries = [];
  final List<Map<String, String>> _revisitEntries = [];
  final Random _random = Random.secure();
  bool _stateLoaded = false;
  bool _isUploading = false;
  int _familyCounter = 1;

  static const List<String> _relationships = [
    'Head',
    'Spouse',
    'Child',
    'Parent',
    'Sibling',
    'Other',
  ];

  static const List<String> _sexOptions = [
    'Male',
    'Female',
    'Other',
  ];

  static const List<String> _maritalStatuses = [
    'Never Married',
    'Married',
    'Widowed',
    'Divorced/Separated',
  ];

  static const List<String> _workStatuses = [
    'Employed',
    'Self-employed',
    'Wage Labor',
    'Student',
    'Unemployed',
    'Homemaker',
    'Retired',
    'Other',
  ];

  static const List<String> _familyEntryTypes = [
    'New',
    'Migrant',
    'Split',
  ];

  static const List<String> _familyFormAssets = [
    'assets/forms/clinical_history.json',
  ];

  static const List<String> _memberFormAssets = [
    'assets/forms/clinical_history.json',
    'assets/forms/clinical_history_follow_up.json',
    'assets/forms/ncd.json',
    'assets/forms/ncd_follow_up.json',
    'assets/forms/anc.json',
    'assets/forms/anc_follow_up.json',
    'assets/forms/pnc.json',
    'assets/forms/pnc_follow_up.json',
    'assets/forms/new_born.json',
    'assets/forms/new_born_follow_up.json',
    'assets/forms/under_5.json',
    'assets/forms/under_5_follow_up.json',
  ];

  static const List<String> _followUpFormIds = [
    'clinical_history_follow_up',
    'ncd_follow_up',
    'anc_follow_up',
    'pnc_follow_up',
    'new_born_follow_up',
    'under_5_follow_up',
  ];

  static const Map<String, String> _formIdToAsset = {
    'clinical_history': 'assets/forms/clinical_history.json',
    'clinical_history_follow_up': 'assets/forms/clinical_history_follow_up.json',
    'ncd': 'assets/forms/ncd.json',
    'ncd_follow_up': 'assets/forms/ncd_follow_up.json',
    'anc': 'assets/forms/anc.json',
    'anc_follow_up': 'assets/forms/anc_follow_up.json',
    'pnc': 'assets/forms/pnc.json',
    'pnc_follow_up': 'assets/forms/pnc_follow_up.json',
    'new_born': 'assets/forms/new_born.json',
    'new_born_follow_up': 'assets/forms/new_born_follow_up.json',
    'under_5': 'assets/forms/under_5.json',
    'under_5_follow_up': 'assets/forms/under_5_follow_up.json',
  };

  final AuthService _authService = AuthService();
  bool get _isIndividualFlow => widget.samplingUnit == 'Individual';
  bool get _isCommunityFlow => widget.samplingUnit == 'Community';
  String get _entryPlace => (widget.setupData['entryPlace'] ?? '').trim();

  @override
  void initState() {
    super.initState();
    _restoreLocalState();
  }

  String _storageKey(String suffix) {
    final area = (widget.setupData['areaCode'] ?? 'NA').trim();
    final sampling = widget.samplingUnit.trim();
    return 'caregrid_${area}_${sampling}_$suffix';
  }

  String _legacyStorageKey(String suffix) {
    final area = (widget.setupData['areaCode'] ?? 'NA').trim();
    final sampling = widget.samplingUnit.trim();
    return 'caregrid_${area}_${sampling}\\_$suffix';
  }

  Future<void> _restoreLocalState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var rawFamilies = prefs.getString(_storageKey('families')) ?? '';
      var rawRevisits = prefs.getString(_storageKey('revisits')) ?? '';
      var savedCounter = prefs.getInt(_storageKey('family_counter'));

      if (rawFamilies.trim().isEmpty) {
        rawFamilies = prefs.getString(_legacyStorageKey('families')) ?? '';
      }
      if (rawRevisits.trim().isEmpty) {
        rawRevisits = prefs.getString(_legacyStorageKey('revisits')) ?? '';
      }
      savedCounter ??= prefs.getInt(_legacyStorageKey('family_counter'));

      if (savedCounter != null && savedCounter > 0) {
        _familyCounter = savedCounter;
      }

      if (rawFamilies.trim().isNotEmpty) {
        final decoded = jsonDecode(rawFamilies);
        if (decoded is List) {
          _familyEntries
            ..clear()
            ..addAll(decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
        }
      }

      if (rawRevisits.trim().isNotEmpty) {
        final decoded = jsonDecode(rawRevisits);
        if (decoded is List) {
          _revisitEntries
            ..clear()
            ..addAll(decoded.whereType<Map>().map((e) => e.map(
                  (k, v) => MapEntry(k.toString(), (v ?? '').toString()),
                )));
        }
      }
    } catch (_) {
      // Fallback to seed.
    }

    if (_familyEntries.isEmpty) {
      _seedSampleFamilyEntry();
    }
    if (!mounted) return;
    setState(() {
      _stateLoaded = true;
    });
    await _persistLocalState();
  }

  Future<void> _persistLocalState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey('families'), jsonEncode(_familyEntries));
      await prefs.setString(_storageKey('revisits'), jsonEncode(_revisitEntries));
      await prefs.setInt(_storageKey('family_counter'), _familyCounter);
    } catch (_) {}
  }

  void _seedSampleFamilyEntry() {
    if (_familyEntries.isNotEmpty) return;
    if (_isCommunityFlow) return;
    final areaCode = (widget.setupData['areaCode'] ?? 'NA')
        .replaceAll('-', '')
        .replaceAll(' ', '');
    final sampleFamilyId = _isIndividualFlow
        ? 'IND-$areaCode-001'
        : 'FAM-$areaCode-001';
    final sampleFamilyUuid = _generateUuid();
    final sampleQr = 'https://caregrid.app/family/$sampleFamilyUuid';
    _familyEntries.add({
      'familyUuid': sampleFamilyUuid,
      'familyId': sampleFamilyId,
      'familyLocation': 'Sample Street, Ward 3',
      'gps': '',
      'qrValue': sampleQr,
      'familyType': _isIndividualFlow ? 'Individual' : 'New',
      'linkedFamilyId': '',
      'gpsCaptured': false,
      'familyStatus': 'Active',
      'memberCount': _isIndividualFlow ? '1' : '2',
      'members': [
        {
          'personUuid': _generateUuid(),
          'fullName': 'Sample Head',
          'relationship': _isIndividualFlow ? 'Self' : 'Head',
          'sex': 'Male',
          'dob': '1990-01-01',
          'age': '34',
          'maritalStatus': 'Married',
          'workStatus': 'Employed',
          'monthlyIncome': '15000',
          'status': 'Alive',
          'clinicalHistory': 'No known conditions.',
          'hasNcd': 'Yes',
          'ncdActive': 'true',
          'knownConditions': 'Hypertension',
          'presentingComplaints': jsonEncode(['Headache', 'Giddiness']),
          'currentMedicationsList': jsonEncode(['Amlodipine 5 mg OD']),
          'allergyHistoryList': jsonEncode(['No known drug allergy']),
          'contactPhone': '9000000001',
          'aadhaar': '',
          'abha': '',
        },
        if (!_isIndividualFlow)
          {
          'personUuid': _generateUuid(),
          'fullName': 'Sample Member',
          'relationship': 'Spouse',
          'sex': 'Female',
          'dob': '1992-06-15',
          'age': '32',
          'maritalStatus': 'Married',
          'workStatus': 'Homemaker',
          'monthlyIncome': '',
          'status': 'Alive',
          'clinicalHistory': '2nd trimester follow-up pending.',
          'pregnancyStatus': 'Pregnant',
          'numberOfKids': '1',
          'presentingComplaints': jsonEncode(['Backache']),
          'knownConditionsList': jsonEncode(['Mild anemia']),
          'currentMedicationsList': jsonEncode(['IFA tablet', 'Calcium tablet']),
          'allergyHistoryList': jsonEncode(['No known allergy']),
          'ancBaseline': jsonEncode({
            'lmp': '2025-09-15',
            'gpla': 'G2P1L1A0',
            'picme': 'PICME123456'
          }),
          'ancHistory': jsonEncode([
            {
              'formId': 'anc',
              'formTitle': 'Antenatal Care (ANC) Field Checklist',
              'followUpDate': DateTime.now()
                  .add(const Duration(days: 14))
                  .toIso8601String()
                  .split('T')
                  .first,
              'values': {
                'visitType': 'First',
                'picme': 'PICME123456',
                'lmp': '2025-09-15',
                'edd': '2026-06-22',
                'gaWeeks': '10',
                'trimester': 'I',
                'totalAncVisits': '1',
                'gpla': 'G2P1L1A0',
                'height': '154',
                'weight': '54',
                'complaints': ['Backache'],
                'coMorbidities': ['Mild anemia']
              }
            }
          ]),
          },
      ],
    });
    if (_isIndividualFlow) {
      return;
    }
    _addRevisitEntry(
      familyId: sampleFamilyId,
      memberName: 'Sample Head',
      formId: 'ncd',
      formTitle: 'NCD Follow-up (Demo)',
      followUpDate: DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String()
          .split('T')
          .first,
    );
    _addRevisitEntry(
      familyId: sampleFamilyId,
      memberName: 'Sample Member',
      formId: 'anc',
      formTitle: 'ANC Follow-up (Demo)',
      followUpDate: DateTime.now()
          .add(const Duration(days: 14))
          .toIso8601String()
          .split('T')
          .first,
    );
  }

  static const List<String> _memberStatuses = [
    'Alive',
    'Migrated',
    'Split',
    'Diseased',
  ];

  bool get isUploading => _isUploading;

  Future<void> uploadEntries() => _uploadEntries();

  List<Map<String, String>> getRevisitEntries() =>
      _revisitEntries.map((e) => Map<String, String>.from(e)).toList();

  void replaceRevisitEntries(List<Map<String, String>> entries) {
    _revisitEntries
      ..clear()
      ..addAll(entries.map((e) => Map<String, String>.from(e)));
    _persistLocalState();
    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> openFollowUpFromDashboard(Map<String, String> row) async {
    final formId = (row['formId'] ?? '').trim();
    if (formId.isEmpty) return false;
    final assetPath = _formIdToAsset[formId];
    if (assetPath == null || assetPath.isEmpty) return false;

    Map<String, dynamic> formMeta = {'id': formId, 'title': formId.toUpperCase()};
    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final parsed = jsonDecode(jsonStr);
      if (parsed is Map<String, dynamic>) {
        formMeta = parsed;
      }
    } catch (_) {}

    final familyId = (row['familyId'] ?? '').trim();
    final memberName = (row['memberName'] ?? '').trim();
    final scope = (row['scope'] ?? '').trim().toLowerCase();
    final isFamilyScope = scope == 'family' || memberName.toLowerCase() == 'family';
    if (familyId.isEmpty) return false;

    Map<String, dynamic>? family;
    for (final f in _familyEntries) {
      if ((f['familyId'] ?? '').toString().trim() == familyId) {
        family = f;
        break;
      }
    }
    if (family == null) return false;

    if (isFamilyScope) {
      if (!mounted) return false;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FormViewerScreen(
            assetPath: assetPath,
            entityLabel: familyId,
          ),
        ),
      );
      final parsedResult = result is Map<String, dynamic> ? result : null;
      final follow = _resolveFollowUpDate(formMeta, parsedResult);
      if (follow.isNotEmpty) {
        _addRevisitEntry(
          familyId: familyId,
          memberName: 'Family',
          formId: formId,
          formTitle:
              (parsedResult?['formTitle'] ?? formMeta['title'] ?? '').toString(),
          followUpDate: follow,
          scope: 'Family',
        );
      }
      if (mounted) setState(() {});
      _persistLocalState();
      return true;
    }

    final members = family['members'] as List<Map<String, String>>? ?? const [];
    Map<String, String>? targetMember;
    for (final m in members) {
      if ((m['fullName'] ?? '').trim() == memberName) {
        targetMember = m;
        break;
      }
    }
    targetMember ??= members.isNotEmpty ? members.first : null;
    if (targetMember == null) return false;

    if (!mounted) return false;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormViewerScreen(
          assetPath: assetPath,
          entityLabel: '${targetMember!['fullName'] ?? ''} ($familyId)',
          contextData: {
            'ancHistory': targetMember['ancHistory'],
            'ancBaseline': targetMember['ancBaseline'],
            'previousEntries': _clinicalNcdHistoryForMember(targetMember),
            'sameDayForms': _sameDaySubmissionForMember(targetMember),
            'visitOptionsByFormId': _visitOptionsByFormIdForMember(targetMember),
          },
        ),
      ),
    );

    _handleMemberFormResult(
      family: family,
      member: targetMember,
      form: formMeta,
      result: result is Map<String, dynamic> ? result : null,
    );
    if (mounted) setState(() {});
    _persistLocalState();
    return true;
  }

  void _addRevisitEntry({
    required String familyId,
    required String memberName,
    required String formId,
    required String formTitle,
    required String followUpDate,
    String scope = 'Individual',
  }) {
    if (followUpDate.trim().isEmpty) return;
    final key = [
      familyId.trim(),
      memberName.trim(),
      formId.trim(),
      followUpDate.trim(),
      scope.trim(),
    ].join('|');
    final exists = _revisitEntries.any((e) {
      final existingKey = [
        (e['familyId'] ?? '').trim(),
        (e['memberName'] ?? '').trim(),
        (e['formId'] ?? '').trim(),
        (e['followUpDate'] ?? '').trim(),
        (e['scope'] ?? '').trim(),
      ].join('|');
      return existingKey == key;
    });
    if (exists) return;
    final category = formId == 'under_5'
        ? 'Under-5'
        : formId == 'new_born'
            ? 'New Born'
            : formId.toUpperCase();
    _revisitEntries.add({
      'familyId': familyId,
      'memberName': memberName,
      'formId': formId,
      'formTitle': formTitle,
      'formCategory': category,
      'followUpDate': followUpDate,
      'status': 'Planned',
      'scope': scope,
    });
    _persistLocalState();
  }

  String _resolveFollowUpDate(
    Map<String, dynamic> form,
    Map<String, dynamic>? result,
  ) {
    if (result?['followUpSkipped'] == true) return '';
    final explicit = (result?['followUpDate'] ?? '').toString().trim();
    if (explicit.isNotEmpty) return explicit;
    final followUp = form['followup'];
    if (followUp is Map<String, dynamic>) {
      final enabled = followUp['enabled'] == true;
      final days = int.tryParse((followUp['defaultCycleDays'] ?? '').toString());
      if (enabled && days != null && days > 0) {
        return DateTime.now()
            .add(Duration(days: days))
            .toIso8601String()
            .split('T')
            .first;
      }
    }
    return '';
  }

  String? _nullIfEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _generateFamilyId() {
    final areaCode = (widget.setupData['areaCode'] ?? 'NA')
        .replaceAll('-', '')
        .replaceAll(' ', '');
    final suffix = _familyCounter.toString().padLeft(3, '0');
    _familyCounter += 1;
    final prefix = _isIndividualFlow ? 'IND' : 'FAM';
    return '$prefix-$areaCode-$suffix';
  }

  String _normalizeIdentifier(String value) {
    return value.trim().toLowerCase();
  }

  Map<String, String>? _findLinkedEntity({
    String? phone,
    String? aadhaar,
    String? abha,
  }) {
    final p = _normalizeIdentifier(phone ?? '');
    final a = _normalizeIdentifier(aadhaar ?? '');
    final b = _normalizeIdentifier(abha ?? '');
    if (p.isEmpty && a.isEmpty && b.isEmpty) return null;

    for (final family in _familyEntries) {
      final familyId = (family['familyId'] ?? '').toString();
      final members = family['members'] as List<Map<String, String>>? ?? const [];
      for (final member in members) {
        final mp = _normalizeIdentifier(member['contactPhone'] ?? '');
        final ma = _normalizeIdentifier(member['aadhaar'] ?? '');
        final mb = _normalizeIdentifier(member['abha'] ?? '');
        final matches = (p.isNotEmpty && p == mp) ||
            (a.isNotEmpty && a == ma) ||
            (b.isNotEmpty && b == mb);
        if (matches) {
          return {
            'familyId': familyId,
            'personUuid': member['personUuid'] ?? '',
            'memberName': member['fullName'] ?? '',
          };
        }
      }
    }
    return null;
  }

  String _generateUuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-'
        '${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-'
        '${h.substring(20, 32)}';
  }

  List<String> _allowedMemberFormIds(Map<String, String> member) {
    final sex = (member['sex'] ?? '').toLowerCase().trim();
    final pregnancy = (member['pregnancyStatus'] ?? '').toLowerCase().trim();
    final age = int.tryParse((member['age'] ?? '').trim()) ?? 0;
    final allowed = <String>{
      'clinical_history',
      'clinical_history_follow_up',
      'ncd',
      'ncd_follow_up',
      'anc',
      'anc_follow_up',
      'pnc',
      'pnc_follow_up',
      'new_born',
      'new_born_follow_up',
      'under_5',
      'under_5_follow_up',
    };

    if (age < 10) {
      allowed.remove('anc');
      allowed.remove('anc_follow_up');
      allowed.remove('pnc');
      allowed.remove('pnc_follow_up');
      allowed.remove('ncd');
      allowed.remove('ncd_follow_up');
    }

    if (sex != 'female') {
      allowed.remove('anc');
      allowed.remove('anc_follow_up');
      allowed.remove('pnc');
      allowed.remove('pnc_follow_up');
      allowed.remove('new_born');
      allowed.remove('new_born_follow_up');
    } else {
      if (pregnancy != 'pregnant') {
        allowed.remove('anc');
        allowed.remove('anc_follow_up');
        allowed.remove('new_born');
        allowed.remove('new_born_follow_up');
      }
      if (pregnancy != 'postpartum') {
        allowed.remove('pnc');
        allowed.remove('pnc_follow_up');
      }
    }
    return allowed.toList();
  }

  List<String> _memberAssetsFor(Map<String, String> member) {
    final allowed = _allowedMemberFormIds(member).toSet();
    final placeAllowed = _allowedFormIdsByEntryPlace();
    return _memberFormAssets.where((asset) {
      final matched = _formIdToAsset.entries
          .where((e) => e.value == asset)
          .map((e) => e.key)
          .toList();
      if (matched.isEmpty) return true;
      return allowed.contains(matched.first) && placeAllowed.contains(matched.first);
    }).toList();
  }

  List<Map<String, dynamic>> _clinicalNcdHistoryForMember(
    Map<String, String> member,
  ) {
    final raw = (member['clinicalHistoryNcdEntries'] ?? '').trim();
    if (raw.isEmpty) return const [];
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

  List<Map<String, dynamic>> _submissionLogForMember(
    Map<String, String> member,
  ) {
    final raw = (member['formSubmissionLog'] ?? '').trim();
    if (raw.isEmpty) return const [];
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

  List<Map<String, dynamic>> _sameDaySubmissionForMember(
    Map<String, String> member,
  ) {
    final today = DateTime.now().toIso8601String().split('T').first;
    return _submissionLogForMember(member).where((entry) {
      final submitted = (entry['submittedAt'] ?? '').toString();
      return submitted.split('T').first == today;
    }).toList();
  }

  List<String> _followUpAssetsFor(Map<String, String> member) {
    final allowed = _allowedMemberFormIds(member).toSet();
    final placeAllowed = _allowedFormIdsByEntryPlace();
    final followIds = _followUpFormIds
        .where((id) => allowed.contains(id) && placeAllowed.contains(id))
        .toList();
    return followIds
        .map((id) => _formIdToAsset[id])
        .whereType<String>()
        .toList();
  }

  static const Map<String, List<String>> _visitFamilies = {
    'clinical_history': ['clinical_history', 'clinical_history_follow_up'],
    'clinical_history_follow_up': ['clinical_history', 'clinical_history_follow_up'],
    'ncd': ['ncd', 'ncd_follow_up'],
    'ncd_follow_up': ['ncd', 'ncd_follow_up'],
    'anc': ['anc', 'anc_follow_up'],
    'anc_follow_up': ['anc', 'anc_follow_up'],
    'pnc': ['pnc', 'pnc_follow_up'],
    'pnc_follow_up': ['pnc', 'pnc_follow_up'],
    'new_born': ['new_born', 'new_born_follow_up'],
    'new_born_follow_up': ['new_born', 'new_born_follow_up'],
    'under_5': ['under_5', 'under_5_follow_up'],
    'under_5_follow_up': ['under_5', 'under_5_follow_up'],
  };

  Map<String, List<String>> _visitOptionsByFormIdForMember(
    Map<String, String> member,
  ) {
    final log = _submissionLogForMember(member);
    final result = <String, List<String>>{};
    for (final family in _visitFamilies.entries) {
      final options = log.where((entry) {
        final formId = (entry['formId'] ?? '').toString();
        return family.value.contains(formId);
      }).map((entry) {
        final title = (entry['formTitle'] ?? entry['formId'] ?? '').toString();
        final submitted = (entry['submittedAt'] ?? '').toString().split('T').first;
        final followUpDate = (entry['followUpDate'] ?? '').toString();
        final suffix = followUpDate.isEmpty ? '' : ' | follow-up $followUpDate';
        return '$title | visit $submitted$suffix';
      }).toList();
      result[family.key] = options;
    }
    return result;
  }

  Future<void> _openQuickFollowUpForMember({
    required Map<String, dynamic> family,
    required Map<String, String> member,
  }) async {
    final assets = _followUpAssetsFor(member);
    if (assets.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No follow-up forms available for this member.')),
      );
      return;
    }
    final followIds = _followUpFormIds
        .where((id) => _allowedMemberFormIds(member).contains(id))
        .toList();
    await _openFormList(
      title: 'Follow-up Forms',
      assets: assets,
      entityLabel: '${member['fullName'] ?? ''} (${family['familyId'] ?? ''})',
      contextData: {
        'ancHistory': member['ancHistory'],
        'ancBaseline': member['ancBaseline'],
        'previousEntries': _clinicalNcdHistoryForMember(member),
        'sameDayForms': _sameDaySubmissionForMember(member),
        'visitOptionsByFormId': _visitOptionsByFormIdForMember(member),
      },
      suggestedFormIds: followIds,
      onSelect: (form, result) {
        _handleMemberFormResult(
          family: family,
          member: member,
          form: form,
          result: result,
        );
        setState(() {});
        _persistLocalState();
      },
    );
  }

  Set<String> _allowedFormIdsByEntryPlace() {
    if (!_isIndividualFlow) {
      return {
        'clinical_history',
        'clinical_history_follow_up',
        'ncd',
        'ncd_follow_up',
        'anc',
        'anc_follow_up',
        'pnc',
        'pnc_follow_up',
        'new_born',
        'new_born_follow_up',
        'under_5',
        'under_5_follow_up',
      };
    }
    if (_entryPlace == 'School' || _entryPlace == 'Anganwadi') {
      return {
        'clinical_history',
        'clinical_history_follow_up',
        'under_5',
        'under_5_follow_up',
      };
    }
    if (_entryPlace == 'Workplace') {
      return {
        'clinical_history',
        'clinical_history_follow_up',
        'ncd',
        'ncd_follow_up',
      };
    }
    return {
      'clinical_history',
      'clinical_history_follow_up',
      'ncd',
      'ncd_follow_up',
      'anc',
      'anc_follow_up',
      'pnc',
      'pnc_follow_up',
      'new_born',
      'new_born_follow_up',
      'under_5',
      'under_5_follow_up',
    };
  }

  void _disposeControllersAfterTransition(
    List<TextEditingController> controllers,
  ) {
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      for (final c in controllers) {
        c.dispose();
      }
    });
  }

  int _calculateAge(String dobIso) {
    final dob = DateTime.tryParse(dobIso);
    if (dob == null) return 0;
    final today = DateTime.now();
    int age = today.year - dob.year;
    final hadBirthday =
        today.month > dob.month || (today.month == dob.month && today.day >= dob.day);
    if (!hadBirthday) age -= 1;
    return age < 0 ? 0 : age;
  }

  Future<Map<String, String>?> _openMemberDialog({
    required int memberIndex,
    Map<String, String>? initial,
  }) async {
    final formKey = GlobalKey<FormState>();
    final fullName = TextEditingController(text: initial?['fullName'] ?? '');
    final dob = TextEditingController(text: initial?['dob'] ?? '');
    final monthlyIncome =
        TextEditingController(text: initial?['monthlyIncome'] ?? '');
    final contactPhone =
        TextEditingController(text: initial?['contactPhone'] ?? '');
    final aadhaar = TextEditingController(text: initial?['aadhaar'] ?? '');
    final abha = TextEditingController(text: initial?['abha'] ?? '');
    String? relationship = _nullIfEmpty(initial?['relationship']);
    String? sex = _nullIfEmpty(initial?['sex']);
    String? maritalStatus = _nullIfEmpty(initial?['maritalStatus']);
    String? workStatus = _nullIfEmpty(initial?['workStatus']);

    Future<void> pickDate(BuildContext dialogContext) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: dialogContext,
        initialDate: DateTime.tryParse(dob.text) ?? now,
        firstDate: DateTime(1900),
        lastDate: now,
      );
      if (picked == null || !dialogContext.mounted) return;
      dob.text = picked.toIso8601String().split('T').first;
    }

    Map<String, String>? result;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text('Member ${memberIndex + 1}'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: fullName,
                          decoration: const InputDecoration(labelText: 'Full Name'),
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ? 'Full Name is required' : null,
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: relationship,
                          items: _relationships
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setLocalState(() => relationship = v),
                          decoration: const InputDecoration(
                            labelText: 'Relationship to Head',
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Relationship is required'
                              : null,
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: sex,
                          items: _sexOptions
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setLocalState(() => sex = v),
                          decoration: const InputDecoration(labelText: 'Sex'),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Sex is required' : null,
                        ),
                        TextFormField(
                          controller: dob,
                          readOnly: true,
                          onTap: () => pickDate(dialogContext),
                          decoration: const InputDecoration(labelText: 'DOB'),
                          validator: (v) => (v ?? '').trim().isEmpty ? 'DOB is required' : null,
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: maritalStatus,
                          items: _maritalStatuses
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setLocalState(() => maritalStatus = v),
                          decoration: const InputDecoration(labelText: 'Marital Status'),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: workStatus,
                          items: _workStatuses
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setLocalState(() => workStatus = v),
                          decoration: const InputDecoration(labelText: 'Work Status'),
                        ),
                        TextFormField(
                          controller: monthlyIncome,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Monthly Income',
                          ),
                        ),
                        TextFormField(
                          controller: contactPhone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number (for linking)',
                          ),
                        ),
                        TextFormField(
                          controller: aadhaar,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Aadhaar (optional)',
                          ),
                        ),
                        TextFormField(
                          controller: abha,
                          decoration: const InputDecoration(
                            labelText: 'ABHA ID (optional)',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    result = {
                      'personUuid': initial?['personUuid'] ?? _generateUuid(),
                      'fullName': fullName.text.trim(),
                      'relationship': relationship ?? '',
                      'sex': sex ?? '',
                      'dob': dob.text.trim(),
                      'age': _calculateAge(dob.text).toString(),
                      'maritalStatus': maritalStatus ?? '',
                      'workStatus': workStatus ?? '',
                      'monthlyIncome': monthlyIncome.text.trim(),
                      'contactPhone': contactPhone.text.trim(),
                      'aadhaar': aadhaar.text.trim(),
                      'abha': abha.text.trim(),
                      'status': initial?['status'] ?? 'Alive',
                      'clinicalHistory': initial?['clinicalHistory'] ?? '',
                    };
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    _disposeControllersAfterTransition([
      fullName,
      dob,
      monthlyIncome,
      contactPhone,
      aadhaar,
      abha,
    ]);
    return result;
  }

  Future<void> _openAddFamilySheet() async {
    if (_isCommunityFlow) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Community data collection is under development.'),
        ),
      );
      return;
    }
    final isIndividualEntry = _isIndividualFlow;
    final familyIdController = TextEditingController(text: _generateFamilyId());
    final familyLocationController = TextEditingController();
    final gpsController = TextEditingController();
    final linkedFamilyIdController = TextEditingController();
    final contactPhoneController = TextEditingController();
    final aadhaarController = TextEditingController();
    final abhaController = TextEditingController();
    final memberCountController = TextEditingController();
    final members = <Map<String, String>?>[];
    String familyEntryType = 'New';

    Future<void> captureGps() async {
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
          return;
        }
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
          return;
        }
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        gpsController.text =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS captured.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS capture failed: $e')),
        );
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final count = int.tryParse(memberCountController.text.trim()) ?? 0;

            void updateMemberList() {
              final targetCount = int.tryParse(memberCountController.text) ?? 0;
              if (targetCount < 0) return;
              while (members.length < targetCount) {
                members.add(null);
              }
              while (members.length > targetCount) {
                members.removeLast();
              }
            }

            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.9,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(dialogContext).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIndividualEntry
                            ? 'Add Individual Entry'
                            : 'Add Family Entry',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: familyIdController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: isIndividualEntry
                              ? 'Individual Unique ID (Auto)'
                              : 'Family Unique ID (Auto)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!isIndividualEntry) ...[
                        TextField(
                          controller: memberCountController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setLocalState(updateMemberList),
                          decoration: const InputDecoration(
                            labelText: 'Number of Family Members',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: familyLocationController,
                        decoration: InputDecoration(
                          labelText: isIndividualEntry
                              ? 'Location (OPD/School/Camp/Workplace)'
                              : 'Family Location (House/Street/Landmark)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: contactPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number (for linking)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: aadhaarController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Aadhaar (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: abhaController,
                        decoration: const InputDecoration(
                          labelText: 'ABHA ID (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: gpsController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'GPS (lat, lng)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: captureGps,
                            icon: const Icon(Icons.my_location),
                            label: const Text('GPS Tag'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!isIndividualEntry)
                        DropdownButtonFormField<String>(
                          initialValue: familyEntryType,
                          items: _familyEntryTypes
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setLocalState(() => familyEntryType = v);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Family Type',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      if (!isIndividualEntry &&
                          (familyEntryType == 'Migrant' || familyEntryType == 'Split'))
                        const SizedBox(height: 12),
                      if (!isIndividualEntry &&
                          (familyEntryType == 'Migrant' || familyEntryType == 'Split'))
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: linkedFamilyIdController,
                                decoration: InputDecoration(
                                  labelText: familyEntryType == 'Migrant'
                                      ? 'Old Family ID (optional)'
                                      : 'Parent Family ID (required)',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Scan QR (to be connected)',
                              onPressed: () {
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'QR scan will be connected in revisit flow.',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.qr_code_scanner),
                            ),
                          ],
                        ),
                      if (isIndividualEntry)
                        const SizedBox(height: 12),
                      if (count > 0 && !isIndividualEntry)
                        const Text(
                          'Add demographic details for each member:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: (isIndividualEntry || count > 0)
                            ? ListView.builder(
                                itemCount: isIndividualEntry ? 1 : members.length,
                                itemBuilder: (context, index) {
                                  if (isIndividualEntry && members.isEmpty) {
                                    members.add(null);
                                  }
                                  final member = members[index];
                                  final isAdded = member != null;
                                  return Card(
                                    child: ListTile(
                                      title: Text(
                                        isIndividualEntry
                                            ? 'Individual Demography'
                                            : 'Member ${index + 1}',
                                      ),
                                      subtitle: Text(
                                        isAdded
                                            ? '${member['fullName']} | ${member['sex']} | Age ${member['age']}'
                                            : 'Not added yet',
                                      ),
                                      trailing: ElevatedButton(
                                        onPressed: () async {
                                          final initial = members[index] == null
                                              ? {
                                                  'contactPhone':
                                                      contactPhoneController.text.trim(),
                                                  'aadhaar':
                                                      aadhaarController.text.trim(),
                                                  'abha': abhaController.text.trim(),
                                                  'relationship':
                                                      isIndividualEntry ? 'Self' : '',
                                                }
                                              : members[index];
                                          final result = await _openMemberDialog(
                                            memberIndex: index,
                                            initial: initial,
                                          );
                                          if (result == null ||
                                              !mounted ||
                                              !context.mounted) {
                                            return;
                                          }
                                          setLocalState(() {
                                            members[index] = result;
                                          });
                                        },
                                        child: Text(isAdded ? 'Edit' : 'Add'),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : const Center(
                                child: Text(
                                  'Enter number of family members to generate add buttons.',
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (!isIndividualEntry && count <= 0) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Enter valid number of family members.'),
                                ),
                              );
                              return;
                            }
                            if (!isIndividualEntry &&
                                familyEntryType == 'Split' &&
                                linkedFamilyIdController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Parent Family ID is required for split families.',
                                  ),
                                ),
                              );
                              return;
                            }
                            final requiredCount = isIndividualEntry ? 1 : count;
                            final filledMembers = members.where((m) => m != null).length;
                            if (filledMembers != requiredCount) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please add all $requiredCount members before saving.',
                                  ),
                                ),
                              );
                              return;
                            }
                            setState(() {
                              final familyId = familyIdController.text.trim();
                              final phone = contactPhoneController.text.trim();
                              final aadhaar = aadhaarController.text.trim();
                              final abha = abhaController.text.trim();
                              final linkedFamilyId = linkedFamilyIdController.text.trim();
                              final autoLinked =
                                  _findLinkedEntity(phone: phone, aadhaar: aadhaar, abha: abha);
                              final normalizedType = familyEntryType == 'Migrant' &&
                                      linkedFamilyId.isEmpty
                                  ? 'New'
                                  : (isIndividualEntry ? 'Individual' : familyEntryType);
                              final familyUuid = _generateUuid();
                              final qrValue =
                                  'https://caregrid.app/family/$familyUuid';
                              final castMembers = members.cast<Map<String, String>>();
                              if (castMembers.isNotEmpty) {
                                castMembers[0]['contactPhone'] =
                                    castMembers[0]['contactPhone'] ?? phone;
                                castMembers[0]['aadhaar'] =
                                    castMembers[0]['aadhaar'] ?? aadhaar;
                                castMembers[0]['abha'] =
                                    castMembers[0]['abha'] ?? abha;
                              }
                              _familyEntries.add({
                                'familyUuid': familyUuid,
                                'familyId': familyId,
                                'familyLocation': familyLocationController.text.trim(),
                                'gps': gpsController.text.trim(),
                                'qrValue': qrValue,
                                'familyType': normalizedType,
                                'linkedFamilyId': linkedFamilyId.isNotEmpty
                                    ? linkedFamilyId
                                    : (autoLinked?['familyId'] ?? ''),
                                'linkedPersonUuid': autoLinked?['personUuid'] ?? '',
                                'contactPhone': phone,
                                'aadhaar': aadhaar,
                                'abha': abha,
                                'gpsCaptured': gpsController.text.trim().isNotEmpty,
                                'allowGpsUpdate': false,
                                'familyStatus':
                                    normalizedType == 'Migrant' ? 'Migrated' : 'Active',
                                'memberCount': requiredCount.toString(),
                                'members': castMembers,
                              });
                            });
                            _persistLocalState();
                            Navigator.pop(dialogContext);
                          },
                          child: Text(
                            isIndividualEntry
                                ? 'Save Individual Entry'
                                : 'Save Family Entry',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    _disposeControllersAfterTransition([
      familyIdController,
      familyLocationController,
      gpsController,
      linkedFamilyIdController,
      contactPhoneController,
      aadhaarController,
      abhaController,
      memberCountController,
    ]);
  }

  Future<void> _captureGpsForFamily(Map<String, dynamic> family) async {
    if (family['gpsCaptured'] == true &&
        (family['allowGpsUpdate'] ?? false) != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS already captured. Edit address to update GPS.'),
        ),
      );
      return;
    }
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        family['gps'] =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        family['gpsCaptured'] = true;
        family['allowGpsUpdate'] = false;
      });
      _persistLocalState();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS captured.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPS capture failed: $e')),
      );
    }
  }

  Future<void> _openLocationApp(Map<String, dynamic> family) async {
    final gpsRaw = (family['gps'] ?? '').toString().trim();
    if (gpsRaw.isEmpty || !gpsRaw.contains(',')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS not captured yet.')),
      );
      return;
    }
    final parts = gpsRaw.split(',');
    if (parts.length < 2) return;
    final lat = parts[0].trim();
    final lng = parts[1].trim();
    final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    final fallback = Uri.parse('https://maps.google.com/?q=$lat,$lng');
    final canLaunchGeo = await canLaunchUrl(uri);
    final canLaunchWeb = await canLaunchUrl(fallback);
    final target = canLaunchGeo ? uri : (canLaunchWeb ? fallback : null);
    if (target == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No map app available.')),
      );
      return;
    }
    await launchUrl(target, mode: LaunchMode.externalApplication);
  }

  Future<void> _openFormList({
    required String title,
    required List<String> assets,
    List<String> suggestedFormIds = const [],
    String? entityLabel,
    Map<String, dynamic>? contextData,
    void Function(Map<String, dynamic> form, Map<String, dynamic>? result)? onSelect,
  }) async {
    final forms = <Map<String, dynamic>>[];
    for (final path in assets) {
      try {
        final jsonStr = await rootBundle.loadString(path);
        final data = jsonDecode(jsonStr);
        if (data is Map<String, dynamic>) {
          forms.add(data..['__asset'] = path);
        }
      } catch (_) {}
    }
    if (suggestedFormIds.isNotEmpty) {
      forms.sort((a, b) {
        final aId = (a['id'] ?? '').toString();
        final bId = (b['id'] ?? '').toString();
        final aRank = suggestedFormIds.contains(aId) ? 0 : 1;
        final bRank = suggestedFormIds.contains(bId) ? 0 : 1;
        if (aRank != bRank) return aRank - bRank;
        return 0;
      });
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 420,
            child: forms.isEmpty
                ? const Text('No forms found.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: forms.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final form = forms[index];
                      final formTitle = (form['title'] ?? form['id'] ?? '').toString();
                      final formId = (form['id'] ?? '').toString();
                      return ListTile(
                        title: Text(formTitle.isEmpty ? 'Untitled Form' : formTitle),
                        subtitle: formId.isEmpty ? null : Text(formId),
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          final assetPath =
                              (form['__asset'] ?? '').toString();
                          Map<String, dynamic>? result;
                          if (assetPath.isNotEmpty) {
                            final response = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FormViewerScreen(
                                  assetPath: assetPath,
                                  entityLabel: entityLabel,
                                  contextData: contextData,
                                ),
                              ),
                            );
                            if (response is Map<String, dynamic>) {
                              result = response;
                            }
                          }
                          onSelect?.call(form, result);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editFamilyAddress(Map<String, dynamic> family) async {
    final controller =
        TextEditingController(text: family['familyLocation']?.toString() ?? '');
    final gpsController = TextEditingController(text: family['gps']?.toString() ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Address'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Family Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: gpsController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'GPS (lat, lng)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        setState(() {
                          family['allowGpsUpdate'] = true;
                        });
                        await _captureGpsForFamily(family);
                        gpsController.text =
                            family['gps']?.toString() ?? gpsController.text;
                      },
                      icon: const Icon(Icons.my_location),
                      label: const Text('GPS Tag'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  family['familyLocation'] = controller.text.trim();
                  family['allowGpsUpdate'] = true;
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (gpsController.text.trim().isNotEmpty) {
      setState(() {
        family['gps'] = gpsController.text.trim();
        family['gpsCaptured'] = true;
      });
      _persistLocalState();
    }
    _disposeControllersAfterTransition([controller, gpsController]);
  }

  Future<void> _uploadEntries() async {
    if (_familyEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No family entries to upload. Add at least one entry.'),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final message = await _syncService.uploadPendingForSamplingUnit(
        samplingUnitId: widget.samplingUnit,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$message | Family entries: ${_familyEntries.length}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _handleMemberFormResult({
    required Map<String, dynamic> family,
    required Map<String, String> member,
    required Map<String, dynamic> form,
    required Map<String, dynamic>? result,
  }) {
    final formId = (result?['formId'] ?? form['id'] ?? '').toString();
    if (result != null) {
      final log = _submissionLogForMember(member);
      final entry = Map<String, dynamic>.from(result);
      entry['submittedAt'] ??= DateTime.now().toIso8601String();
      log.add(entry);
      member['formSubmissionLog'] = jsonEncode(log);
    }
    if (formId == 'ncd') {
      member['ncdActive'] = 'true';
    }
    if (formId == 'anc' && result != null) {
      final history = <dynamic>[];
      final historyRaw = member['ancHistory'];
      if ((historyRaw ?? '').trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(historyRaw!);
          if (decoded is List) {
            history.addAll(decoded);
          }
        } catch (_) {}
      }
      history.add(result);
      member['ancHistory'] = jsonEncode(history);
      final baseline = (result['ancBaseline'] as Map<String, dynamic>? ??
              const <String, dynamic>{})
          .map((k, v) => MapEntry(k, (v ?? '').toString()));
      member['ancBaseline'] = jsonEncode(baseline);
    }
    if (formId == 'clinical_history_ncd' && result != null) {
      final history = _clinicalNcdHistoryForMember(member);
      history.add(Map<String, dynamic>.from(result));
      member['clinicalHistoryNcdEntries'] = jsonEncode(history);
      final values = result['values'] as Map<String, dynamic>? ?? const {};
      List<String> decodeTextList(dynamic raw) {
        if (raw is List) {
          return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        }
        final text = (raw ?? '').toString().trim();
        if (text.isEmpty) return const [];
        try {
          final parsed = jsonDecode(text);
          if (parsed is List) {
            return parsed
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
        } catch (_) {}
        return [text];
      }

      List<String> decodeGroupRows(
        dynamic raw,
        List<String> keys,
      ) {
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
              final t = (map[k] ?? '').trim();
              if (t.isNotEmpty) chunks.add(t);
            }
            if (chunks.isNotEmpty) rows.add(chunks.join(' | '));
          }
          return rows;
        } catch (_) {
          return const [];
        }
      }
      final complaintsRaw = (values['chief_complaints'] ?? '').toString();
      if (complaintsRaw.trim().isNotEmpty) {
        try {
          final parsed = jsonDecode(complaintsRaw);
          if (parsed is List) {
            final labels = parsed
                .whereType<Map>()
                .map((e) => (e['complaint'] ?? '').toString().trim())
                .where((e) => e.isNotEmpty)
                .toList();
            if (labels.isNotEmpty) {
              member['presentingComplaints'] = jsonEncode(labels);
              member['chiefComplaints'] = labels.join(' | ');
            }
          }
        } catch (_) {}
      }
      final includeSameDay =
          (values['include_same_day_in_final_treatment'] ?? 'Yes').toString() == 'Yes';
      final sameDayTreat = decodeTextList(values['same_day_treatments_readonly']);
      final sameDayInv = decodeTextList(values['same_day_investigations_readonly']);
      final addonTreat = decodeGroupRows(
        values['additional_treatments'],
        const ['medication', 'dose', 'frequency', 'period'],
      );
      final addonInv = decodeGroupRows(
        values['additional_investigations'],
        const ['investigation', 'frequency', 'period'],
      );
      final treatmentBlock = <String>[
        if (includeSameDay) ...sameDayTreat,
        ...addonTreat,
        ...decodeTextList(values['overall_treatment_plan']),
        ...decodeTextList(values['treatment_plan']),
        ...decodeTextList(values['prescription_details']),
      ];
      final investigationBlock = <String>[
        if (includeSameDay) ...sameDayInv,
        ...addonInv,
        ...decodeTextList(values['overall_investigation_plan']),
        ...decodeTextList(values['investigations_to_do']),
      ];
      member['finalTreatmentReadonly'] = treatmentBlock.join('\n');
      member['finalInvestigationReadonly'] = investigationBlock.join('\n');
      member['finalAdviceReadonly'] = (values['final_notes_advice'] ?? '').toString();
      member['finalDiagnosisReadonly'] = (values['working_diagnosis'] ?? '').toString();
    }
    final followForNcd = _resolveFollowUpDate(form, result);
    _addRevisitEntry(
      familyId: (family['familyId'] ?? '').toString(),
      memberName: (member['fullName'] ?? '').toString(),
      formId: formId,
      formTitle: (result?['formTitle'] ?? form['title'] ?? '').toString(),
      followUpDate: followForNcd,
    );
    _persistLocalState();
  }

  Future<void> _openIndividualProfile({
    required Map<String, dynamic> family,
    required Map<String, String> member,
  }) async {
    final familyMemberCount =
        (family['members'] as List<Map<String, String>>?)?.length ??
            int.tryParse((family['memberCount'] ?? '').toString()) ??
            0;
    final response = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IndividualProfileScreen(
          member: member,
          familyId: (family['familyId'] ?? '').toString(),
          familyMemberCount: familyMemberCount,
        ),
      ),
    );
    if (response is! Map<String, dynamic> || !mounted) return;

    final updatedMember = response['member'];
    if (updatedMember is Map<String, String>) {
      member
        ..clear()
        ..addAll(updatedMember);
    } else if (updatedMember is Map) {
      member
        ..clear()
        ..addAll(
          updatedMember.map(
            (k, v) => MapEntry(k.toString(), (v ?? '').toString()),
          ),
        );
    }

    final allowedIds = _allowedMemberFormIds(member).toSet();
    final suggested = (response['suggestedFormIds'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where(allowedIds.contains)
        .toList();
    final requiredAddons =
        (response['requiredAddonFormIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .where(allowedIds.contains)
            .toList();
    final shouldOpenForms = response['openForms'] == true;

    setState(() {});
    _persistLocalState();
    if (!shouldOpenForms) return;

    final immediateForms = <String>[];
    immediateForms.addAll(requiredAddons);
    for (final id in suggested) {
      if (!immediateForms.contains(id)) {
        immediateForms.add(id);
      }
    }

    if (immediateForms.isNotEmpty) {
      for (final formId in immediateForms) {
        if (!mounted) return;
        final assetPath = _formIdToAsset[formId];
        if (assetPath == null) continue;
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FormViewerScreen(
              assetPath: assetPath,
              entityLabel:
                  '${member['fullName'] ?? ''} (${family['familyId'] ?? ''})',
              contextData: {
                'ancHistory': member['ancHistory'],
                'ancBaseline': member['ancBaseline'],
                'previousEntries': _clinicalNcdHistoryForMember(member),
                'sameDayForms': _sameDaySubmissionForMember(member),
                'visitOptionsByFormId': _visitOptionsByFormIdForMember(member),
              },
            ),
          ),
        );
        Map<String, dynamic> formMeta = {'id': formId, 'title': formId.toUpperCase()};
        try {
          final jsonStr = await rootBundle.loadString(assetPath);
          final parsed = jsonDecode(jsonStr);
          if (parsed is Map<String, dynamic>) {
            formMeta = parsed;
          }
        } catch (_) {}
        _handleMemberFormResult(
          family: family,
          member: member,
          form: formMeta,
          result: result is Map<String, dynamic> ? result : null,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Immediate forms completed: ${immediateForms.join(', ').toUpperCase()}',
          ),
        ),
      );
      setState(() {});
      _persistLocalState();
      return;
    }

    final allowedAssets = _memberAssetsFor(member);
    await _openFormList(
      title: 'Member Forms',
      assets: allowedAssets,
      entityLabel:
          '${member['fullName'] ?? ''} (${family['familyId'] ?? ''})',
      contextData: {
        'ancHistory': member['ancHistory'],
        'ancBaseline': member['ancBaseline'],
        'previousEntries': _clinicalNcdHistoryForMember(member),
        'sameDayForms': _sameDaySubmissionForMember(member),
        'visitOptionsByFormId': _visitOptionsByFormIdForMember(member),
      },
      suggestedFormIds: suggested,
      onSelect: (form, result) {
        _handleMemberFormResult(
          family: family,
          member: member,
          form: form,
          result: result,
        );
        setState(() {});
        _persistLocalState();
      },
    );
  }

  Future<void> _addMemberToFamily(Map<String, dynamic> family) async {
    final members = family['members'] as List<Map<String, String>>;
    final result = await _openMemberDialog(
      memberIndex: members.length,
      initial: null,
    );
    if (result == null || !mounted) return;
    setState(() {
      members.add(result);
      family['memberCount'] = members.length.toString();
    });
    _persistLocalState();
  }

  @override
  Widget build(BuildContext context) {
    if (!_stateLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridContextCard(
            samplingUnit: widget.samplingUnit,
            setupData: widget.setupData,
          ),
          const SizedBox(height: 12),
          FamilyListHeader(
            familyCount: _familyEntries.length,
            entryLabel: _isIndividualFlow ? 'Individual' : 'Family',
            onAddEntry: _openAddFamilySheet,
          ),
          const SizedBox(height: 8),
          Expanded(
                child: _familyEntries.isEmpty
                    ? Center(
                        child: Text(
                          _isIndividualFlow
                              ? 'No individual entries yet. Click Add Entry to start.'
                              : 'No family entries yet. Click Add Entry to start.',
                        ),
                      )
                : ListView.builder(
                    itemCount: _familyEntries.length,
                    itemBuilder: (context, index) {
                      final family = _familyEntries[index];
                      final members = family['members'] as List<Map<String, String>>;
                      return Card(
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(family['familyId']?.toString() ?? ''),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Update status via menu.',
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  (family['familyStatus'] ?? 'Active').toString(),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                tooltip: 'Location',
                                onPressed: () => _openLocationApp(family),
                                icon: const Icon(Icons.map_outlined),
                              ),
                              if (!_isIndividualFlow)
                                IconButton(
                                  tooltip: 'Family Forms',
                                  onPressed: () => _openFormList(
                                    title: 'Family Forms',
                                    assets: _familyFormAssets,
                                    entityLabel: family['familyId']?.toString(),
                                    onSelect: (form, result) {
                                      final follow = _resolveFollowUpDate(form, result);
                                      if (follow.isEmpty) return;
                                      _addRevisitEntry(
                                        familyId: (family['familyId'] ?? '').toString(),
                                        memberName: 'Family',
                                        formId:
                                            (result?['formId'] ?? form['id'] ?? '').toString(),
                                        formTitle: (result?['formTitle'] ??
                                                form['title'] ??
                                                '')
                                            .toString(),
                                        followUpDate: follow,
                                        scope: 'Family',
                                      );
                                      setState(() {});
                                      _persistLocalState();
                                    },
                                  ),
                                  icon: const Icon(Icons.article_outlined),
                                ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'id_card':
                                      final familyId =
                                          (family['familyId'] ?? '').toString();
                                      final streetOrLocality =
                                          (family['familyLocation'] ?? '')
                                              .toString()
                                              .trim();
                                      final taluk =
                                          (widget.setupData['taluk'] ?? '').trim();
                                      final district =
                                          (widget.setupData['district'] ?? '').trim();
                                      final state =
                                          (widget.setupData['state'] ?? '').trim();
                                      final addressParts = <String>[
                                        if (streetOrLocality.isNotEmpty)
                                          streetOrLocality,
                                        if (taluk.isNotEmpty) taluk,
                                        if (district.isNotEmpty) district,
                                        if (state.isNotEmpty) state,
                                      ];
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => IdCardScreen(
                                            organizationName:
                                                _authService.currentOrganizationName ??
                                                    'Demo Organization',
                                            familyId: familyId,
                                            qrValue:
                                                (family['qrValue'] ?? '').toString(),
                                            members: (family['members']
                                                    as List<Map<String, String>>)
                                                .toList(),
                                            address: addressParts.join(', '),
                                            issuedBy:
                                                _authService.currentUserName ?? '',
                                          ),
                                        ),
                                      );
                                      break;
                                    case 'status_active':
                                      setState(() {
                                        family['familyStatus'] = 'Active';
                                      });
                                      _persistLocalState();
                                      break;
                                    case 'status_migrated':
                                      setState(() {
                                        family['familyStatus'] = 'Migrated';
                                      });
                                      _persistLocalState();
                                      break;
                                    case 'status_dissolved':
                                      setState(() {
                                        family['familyStatus'] = 'Dissolved';
                                      });
                                      _persistLocalState();
                                      break;
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'id_card',
                                    child: Text('ID Card'),
                                  ),
                                  PopupMenuItem(
                                    value: 'status_active',
                                    child: Text('Status: Active'),
                                  ),
                                  PopupMenuItem(
                                    value: 'status_migrated',
                                    child: Text('Status: Migrated'),
                                  ),
                                  PopupMenuItem(
                                    value: 'status_dissolved',
                                    child: Text('Status: Dissolved'),
                                  ),
                                ],
                                icon: const Icon(Icons.more_vert),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Type: ${family['familyType'] ?? 'New'} | '
                            'Members: ${family['memberCount'] ?? '0'}',
                          ),
                          children: [
                            ListTile(
                              title: Text(
                                _isIndividualFlow
                                    ? 'Entry Location'
                                    : 'Family Location',
                              ),
                              subtitle: Text(
                                (family['familyLocation'] ?? '').toString().isEmpty
                                    ? '-'
                                    : family['familyLocation'].toString(),
                              ),
                              trailing: OutlinedButton.icon(
                                onPressed: () => _editFamilyAddress(family),
                                icon: const Icon(Icons.edit_location_alt),
                                label: const Text('Edit Address'),
                              ),
                            ),
                            ...members.map<Widget>(
                              (m) => ListTile(
                                title: Text(m['fullName'] ?? ''),
                                subtitle: Text(
                                  '${m['relationship'] ?? '-'} | '
                                  '${m['sex'] ?? '-'} | '
                                  'Age ${m['age'] ?? '-'} | '
                                  'Income ${m['monthlyIncome']?.isEmpty == true ? '-' : m['monthlyIncome']} | '
                                  'Status ${m['status'] ?? 'Alive'}'
                                  '${(m['contactPhone'] ?? '').trim().isNotEmpty ? ' | Phone ${m['contactPhone']}' : ''}'
                                  '${(m['abha'] ?? '').trim().isNotEmpty ? ' | ABHA ${m['abha']}' : ''}',
                                ),
                                onTap: () => _openIndividualProfile(
                                  family: family,
                                  member: m,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                      IconButton(
                                      tooltip: 'Profile',
                                      onPressed: () => _openIndividualProfile(
                                        family: family,
                                        member: m,
                                      ),
                                      icon: const Icon(Icons.person_outline),
                                      ),
                                      IconButton(
                                        tooltip: 'Add Follow-up',
                                        onPressed: () => _openQuickFollowUpForMember(
                                          family: family,
                                          member: m,
                                        ),
                                        icon: const Icon(Icons.event_available_outlined),
                                      ),
                                      IconButton(
                                        tooltip: 'Forms',
                                        onPressed: () => _openFormList(
                                          title: 'Member Forms',
                                          assets: _memberAssetsFor(m),
                                          entityLabel:
                                              '${m['fullName'] ?? ''} (${family['familyId'] ?? ''})',
                                          contextData: {
                                            'ancHistory': m['ancHistory'],
                                            'ancBaseline': m['ancBaseline'],
                                            'previousEntries':
                                                _clinicalNcdHistoryForMember(m),
                                            'sameDayForms':
                                                _sameDaySubmissionForMember(m),
                                            'visitOptionsByFormId':
                                                _visitOptionsByFormIdForMember(m),
                                          },
                                          suggestedFormIds: const [],
                                          onSelect: (form, result) {
                                            _handleMemberFormResult(
                                              family: family,
                                              member: m,
                                              form: form,
                                              result: result,
                                            );
                                            setState(() {});
                                            _persistLocalState();
                                          },
                                        ),
                                        icon: const Icon(Icons.article_outlined),
                                      ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        setState(() {
                                          m['status'] = value;
                                        });
                                        _persistLocalState();
                                      },
                                      itemBuilder: (context) => _memberStatuses
                                          .map(
                                            (s) => PopupMenuItem<String>(
                                              value: s,
                                              child: Text(s),
                                            ),
                                          )
                                          .toList(),
                                      icon: const Icon(Icons.more_vert),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if ((family['contactPhone'] ?? '').toString().trim().isNotEmpty ||
                                (family['aadhaar'] ?? '').toString().trim().isNotEmpty ||
                                (family['abha'] ?? '').toString().trim().isNotEmpty ||
                                (family['linkedFamilyId'] ?? '').toString().trim().isNotEmpty)
                              ListTile(
                                title: const Text('Linking Identifiers'),
                                subtitle: Text(
                                  'Phone: ${(family['contactPhone'] ?? '-').toString()} | '
                                  'Aadhaar: ${(family['aadhaar'] ?? '-').toString()} | '
                                  'ABHA: ${(family['abha'] ?? '-').toString()} | '
                                  'Linked Family: ${(family['linkedFamilyId'] ?? '-').toString()}',
                                ),
                              ),
                          ]
                            ..addAll(
                              _isIndividualFlow
                                  ? const <Widget>[]
                                  : [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          8,
                                          16,
                                          8,
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _addMemberToFamily(family),
                                            icon: const Icon(Icons.person_add),
                                            label: const Text('Add Member'),
                                          ),
                                        ),
                                      ),
                                    ],
                            )
                            ..addAll(
                              (family['linkedFamilyId'] ?? '')
                                      .toString()
                                      .trim()
                                      .isNotEmpty
                                  ? [
                                      ListTile(
                                        title: Text(
                                          family['familyType'] == 'Split'
                                              ? 'Parent Family ID'
                                              : 'Old Family ID',
                                        ),
                                        subtitle:
                                            Text(family['linkedFamilyId'].toString()),
                                      ),
                                    ]
                                  : const [],
                            )
                            ..add(
                              ListTile(
                                title: const Text('QR Link Value'),
                                subtitle: Text(family['qrValue']?.toString() ?? '-'),
                              ),
                            )
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
