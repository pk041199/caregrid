import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/sync_service.dart';
import 'follow_up_dashboard_screen.dart';
import 'form_viewer_screen.dart';
import 'widgets/data_collection_widgets.dart';

class IndividualDataCollectionSection extends StatefulWidget {
  const IndividualDataCollectionSection({
    super.key,
    required this.samplingUnit,
    required this.setupData,
  });

  final String samplingUnit;
  final Map<String, String> setupData;

  @override
  State<IndividualDataCollectionSection> createState() =>
      IndividualDataCollectionSectionState();
}

class IndividualDataCollectionSectionState
    extends State<IndividualDataCollectionSection> {
  final SyncService _syncService = SyncService();
  final Random _random = Random.secure();
  final List<Map<String, String>> _entries = [];
  final List<Map<String, String>> _revisitEntries = [];
  bool _stateLoaded = false;
  bool _isUploading = false;
  int _counter = 1;

  static const List<String> _sexOptions = ['Male', 'Female', 'Other'];
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
  static const List<String> _statusOptions = [
    'Active',
    'Migrated',
    'Split',
    'Diseased',
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

  bool get isUploading => _isUploading;

  String _storageKey(String suffix) {
    final area = (widget.setupData['areaCode'] ?? 'NA').trim();
    return 'caregrid_${area}_Individual_$suffix';
  }

  @override
  void initState() {
    super.initState();
    _restoreLocalState();
  }

  Future<void> _restoreLocalState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawEntries = prefs.getString(_storageKey('entries')) ?? '';
      final rawRevisits = prefs.getString(_storageKey('revisits')) ?? '';
      final savedCounter = prefs.getInt(_storageKey('counter'));
      if (savedCounter != null && savedCounter > 0) _counter = savedCounter;

      if (rawEntries.trim().isNotEmpty) {
        final decoded = jsonDecode(rawEntries);
        if (decoded is List) {
          _entries
            ..clear()
            ..addAll(decoded.whereType<Map>().map(
                  (e) => e.map(
                    (k, v) => MapEntry(k.toString(), (v ?? '').toString()),
                  ),
                ));
        }
      }
      if (rawRevisits.trim().isNotEmpty) {
        final decoded = jsonDecode(rawRevisits);
        if (decoded is List) {
          _revisitEntries
            ..clear()
            ..addAll(decoded.whereType<Map>().map(
                  (e) => e.map(
                    (k, v) => MapEntry(k.toString(), (v ?? '').toString()),
                  ),
                ));
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _stateLoaded = true);
    await _persistLocalState();
  }

  Future<void> _persistLocalState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey('entries'), jsonEncode(_entries));
      await prefs.setString(_storageKey('revisits'), jsonEncode(_revisitEntries));
      await prefs.setInt(_storageKey('counter'), _counter);
    } catch (_) {}
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

  String _generateIndividualId() {
    final areaCode = (widget.setupData['areaCode'] ?? 'NA')
        .replaceAll('-', '')
        .replaceAll(' ', '');
    final suffix = _counter.toString().padLeft(3, '0');
    _counter += 1;
    return 'IND-$areaCode-$suffix';
  }

  int _calculateAge(String dobIso) {
    final dob = DateTime.tryParse(dobIso);
    if (dob == null) return 0;
    final today = DateTime.now();
    var age = today.year - dob.year;
    final hadBirthday =
        today.month > dob.month || (today.month == dob.month && today.day >= dob.day);
    if (!hadBirthday) age -= 1;
    return age < 0 ? 0 : age;
  }

  List<String> _assetsForEntry(Map<String, String> entry) {
    final sex = (entry['sex'] ?? '').toLowerCase().trim();
    final age = int.tryParse((entry['age'] ?? '').trim()) ?? 0;
    final pregnancy = (entry['pregnancyStatus'] ?? '').toLowerCase().trim();
    final place = (widget.setupData['entryPlace'] ?? '').trim();
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
      allowed.removeAll({
        'anc',
        'anc_follow_up',
        'pnc',
        'pnc_follow_up',
        'ncd',
        'ncd_follow_up',
      });
    }
    if (sex != 'female') {
      allowed.removeAll({'anc', 'anc_follow_up', 'pnc', 'pnc_follow_up', 'new_born', 'new_born_follow_up'});
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

    if (place == 'School' || place == 'Anganwadi') {
      allowed.retainAll({
        'clinical_history',
        'clinical_history_follow_up',
        'under_5',
        'under_5_follow_up',
      });
    } else if (place == 'Workplace') {
      allowed.retainAll({
        'clinical_history',
        'clinical_history_follow_up',
        'ncd',
        'ncd_follow_up',
      });
    }

    return _formIdToAsset.entries
        .where((e) => allowed.contains(e.key))
        .map((e) => e.value)
        .toList();
  }

  String _resolveFollowUpDate(
    Map<String, dynamic> form,
    Map<String, dynamic>? result,
  ) {
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

  Map<String, List<String>> _visitOptionsByFormIdForEntry(
    Map<String, String> entry,
  ) {
    final raw = (entry['formSubmissionLog'] ?? '').trim();
    if (raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const {};
      final log = decoded
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
      final result = <String, List<String>>{};
      for (final family in _visitFamilies.entries) {
        result[family.key] = log.where((item) {
          final formId = (item['formId'] ?? '').toString();
          return family.value.contains(formId);
        }).map((item) {
          final title = (item['formTitle'] ?? item['formId'] ?? '').toString();
          final submitted = (item['submittedAt'] ?? '').toString().split('T').first;
          final followUpDate = (item['followUpDate'] ?? '').toString();
          final suffix = followUpDate.isEmpty ? '' : ' | follow-up $followUpDate';
          return '$title | visit $submitted$suffix';
        }).toList();
      }
      return result;
    } catch (_) {
      return const {};
    }
  }

  void _addRevisitEntry({
    required String individualId,
    required String memberName,
    required String formId,
    required String formTitle,
    required String followUpDate,
  }) {
    if (followUpDate.trim().isEmpty) return;
    final category = formId == 'under_5'
        ? 'Under-5'
        : formId == 'new_born'
            ? 'New Born'
            : formId.toUpperCase();
    _revisitEntries.add({
      'familyId': individualId,
      'memberName': memberName,
      'formId': formId,
      'formTitle': formTitle,
      'formCategory': category,
      'followUpDate': followUpDate,
      'status': 'Planned',
      'scope': 'Individual',
    });
  }

  List<Map<String, String>> getRevisitEntries() =>
      _revisitEntries.map((e) => Map<String, String>.from(e)).toList();

  void replaceRevisitEntries(List<Map<String, String>> entries) {
    _revisitEntries
      ..clear()
      ..addAll(entries.map((e) => Map<String, String>.from(e)));
    _persistLocalState();
    if (mounted) setState(() {});
  }

  Future<bool> openFollowUpFromDashboard(Map<String, String> row) async {
    final formId = (row['formId'] ?? '').trim();
    if (formId.isEmpty) return false;
    final assetPath = _formIdToAsset[formId];
    if (assetPath == null || assetPath.isEmpty) return false;

    Map<String, dynamic> formMeta = {'id': formId, 'title': formId.toUpperCase()};
    try {
      final formStr = await rootBundle.loadString(assetPath);
      final parsed = jsonDecode(formStr);
      if (parsed is Map<String, dynamic>) {
        formMeta = parsed;
      }
    } catch (_) {}

    final individualId = (row['familyId'] ?? '').trim();
    final memberName = (row['memberName'] ?? '').trim();
    Map<String, String>? entry;
    for (final e in _entries) {
      if ((e['individualId'] ?? '').trim() == individualId) {
        entry = e;
        break;
      }
    }
    if (entry == null && memberName.isNotEmpty) {
      for (final e in _entries) {
        if ((e['fullName'] ?? '').trim() == memberName) {
          entry = e;
          break;
        }
      }
    }
    if (entry == null) return false;

    if (!mounted) return false;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormViewerScreen(
          assetPath: assetPath,
          entityLabel:
              '${entry!['fullName'] ?? ''} (${entry['individualId'] ?? ''})',
          contextData: {
            'ancHistory': entry['ancHistory'],
            'ancBaseline': entry['ancBaseline'],
            'visitOptionsByFormId': _visitOptionsByFormIdForEntry(entry),
          },
        ),
      ),
    );

    _handleFormResult(
      entry: entry,
      form: formMeta,
      result: result is Map<String, dynamic> ? result : null,
    );
    if (mounted) setState(() {});
    _persistLocalState();
    return true;
  }

  Future<void> uploadEntries() async {
    if (_isUploading) return;
    if (_entries.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No individual entries to upload.')),
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
        SnackBar(content: Text('$message | Individual entries: ${_entries.length}')),
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

  Future<void> _openFormList({
    required List<String> assets,
    required String entityLabel,
    required void Function(Map<String, dynamic> form, Map<String, dynamic>? result)
        onSelect,
    Map<String, dynamic>? contextData,
  }) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView.builder(
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];
              final fileName = asset.split('/').last;
              return ListTile(
                title: Text(fileName.replaceAll('.json', '').replaceAll('_', ' ').toUpperCase()),
                subtitle: Text(asset),
                onTap: () async {
                  final formStr = await rootBundle.loadString(asset);
                  final parsed = jsonDecode(formStr);
                  if (parsed is! Map<String, dynamic>) return;
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FormViewerScreen(
                        assetPath: asset,
                        entityLabel: entityLabel,
                        contextData: contextData,
                      ),
                    ),
                  );
                  if (result is Map<String, dynamic>) {
                    onSelect(parsed, result);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<Map<String, String>?> _openIndividualDialog({
    Map<String, String>? initial,
  }) async {
    final formKey = GlobalKey<FormState>();
    final idController =
        TextEditingController(text: initial?['individualId'] ?? _generateIndividualId());
    final fullName = TextEditingController(text: initial?['fullName'] ?? '');
    final dob = TextEditingController(text: initial?['dob'] ?? '');
    final monthlyIncome =
        TextEditingController(text: initial?['monthlyIncome'] ?? '');
    final contactPhone =
        TextEditingController(text: initial?['contactPhone'] ?? '');
    final aadhaar = TextEditingController(text: initial?['aadhaar'] ?? '');
    final abha = TextEditingController(text: initial?['abha'] ?? '');
    final location = TextEditingController(
      text: initial?['location'] ?? (widget.setupData['entryPlace'] ?? ''),
    );

    String sex = (initial?['sex'] ?? 'Male').trim();
    String maritalStatus = (initial?['maritalStatus'] ?? _maritalStatuses.first).trim();
    String workStatus = (initial?['workStatus'] ?? _workStatuses.first).trim();
    String status = (initial?['status'] ?? 'Active').trim();
    String pregnancyStatus = (initial?['pregnancyStatus'] ?? 'Not Applicable').trim();

    Future<void> pickDate(BuildContext dialogContext) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: dialogContext,
        initialDate: DateTime(now.year - 20, now.month, now.day),
        firstDate: DateTime(1900),
        lastDate: now,
      );
      if (picked == null) return;
      dob.text = picked.toIso8601String().split('T').first;
    }

    Map<String, String>? result;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setLocalState) {
            final isFemale = sex.toLowerCase() == 'female';
            if (!isFemale) pregnancyStatus = 'Not Applicable';
            return AlertDialog(
              title: const Text('Individual Demography'),
              content: SizedBox(
                width: 560,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: idController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Individual Unique ID',
                          ),
                        ),
                        TextFormField(
                          controller: fullName,
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ? 'Name required' : null,
                          decoration: const InputDecoration(labelText: 'Full Name'),
                        ),
                        TextFormField(
                          controller: contactPhone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                          ),
                        ),
                        TextFormField(
                          controller: aadhaar,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Aadhaar'),
                        ),
                        TextFormField(
                          controller: abha,
                          decoration: const InputDecoration(labelText: 'ABHA ID'),
                        ),
                        TextFormField(
                          controller: dob,
                          readOnly: true,
                          onTap: () => pickDate(dialogContext),
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ? 'DOB required' : null,
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: sex,
                          items: _sexOptions
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setLocalState(() => sex = v);
                          },
                          decoration: const InputDecoration(labelText: 'Sex'),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: maritalStatus,
                          items: _maritalStatuses
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setLocalState(() => maritalStatus = v);
                          },
                          decoration: const InputDecoration(labelText: 'Marital Status'),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: workStatus,
                          items: _workStatuses
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setLocalState(() => workStatus = v);
                          },
                          decoration: const InputDecoration(labelText: 'Work Status'),
                        ),
                        TextFormField(
                          controller: monthlyIncome,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Monthly Income'),
                        ),
                        TextFormField(
                          controller: location,
                          decoration: const InputDecoration(labelText: 'Entry Location'),
                        ),
                        if (isFemale)
                          DropdownButtonFormField<String>(
                            initialValue: pregnancyStatus,
                            items: const [
                              DropdownMenuItem(
                                value: 'Not Pregnant',
                                child: Text('Not Pregnant'),
                              ),
                              DropdownMenuItem(
                                value: 'Pregnant',
                                child: Text('Pregnant'),
                              ),
                              DropdownMenuItem(
                                value: 'Postpartum',
                                child: Text('Postpartum'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setLocalState(() => pregnancyStatus = v);
                            },
                            decoration:
                                const InputDecoration(labelText: 'Pregnancy Status'),
                          ),
                        DropdownButtonFormField<String>(
                          initialValue: status,
                          items: _statusOptions
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setLocalState(() => status = v);
                          },
                          decoration: const InputDecoration(labelText: 'Status'),
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
                    final dobText = dob.text.trim();
                    result = {
                      'personUuid': initial?['personUuid'] ?? _generateUuid(),
                      'individualId': idController.text.trim(),
                      'fullName': fullName.text.trim(),
                      'contactPhone': contactPhone.text.trim(),
                      'aadhaar': aadhaar.text.trim(),
                      'abha': abha.text.trim(),
                      'dob': dobText,
                      'age': _calculateAge(dobText).toString(),
                      'sex': sex,
                      'maritalStatus': maritalStatus,
                      'workStatus': workStatus,
                      'monthlyIncome': monthlyIncome.text.trim(),
                      'location': location.text.trim(),
                      'pregnancyStatus': pregnancyStatus,
                      'status': status,
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

    idController.dispose();
    fullName.dispose();
    dob.dispose();
    monthlyIncome.dispose();
    contactPhone.dispose();
    aadhaar.dispose();
    abha.dispose();
    location.dispose();
    return result;
  }

  Future<void> _addEntry() async {
    final entry = await _openIndividualDialog();
    if (entry == null || !mounted) return;
    setState(() {
      _entries.add(entry);
    });
    _persistLocalState();
  }

  Future<void> _editEntry(int index) async {
    final updated = await _openIndividualDialog(initial: _entries[index]);
    if (updated == null || !mounted) return;
    setState(() => _entries[index] = updated);
    _persistLocalState();
  }

  void _handleFormResult({
    required Map<String, String> entry,
    required Map<String, dynamic> form,
    required Map<String, dynamic>? result,
  }) {
    final formId = (result?['formId'] ?? form['id'] ?? '').toString();
    if (formId.isEmpty) return;
    if (result != null) {
      final log = <dynamic>[];
      final rawLog = (entry['formSubmissionLog'] ?? '').trim();
      if (rawLog.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawLog);
          if (decoded is List) log.addAll(decoded);
        } catch (_) {}
      }
      final saved = Map<String, dynamic>.from(result);
      saved['submittedAt'] ??= DateTime.now().toIso8601String();
      log.add(saved);
      entry['formSubmissionLog'] = jsonEncode(log);
    }
    if (formId == 'ncd') entry['ncdActive'] = 'true';
    if (formId == 'anc' && result != null) {
      final history = <dynamic>[];
      final raw = entry['ancHistory'] ?? '';
      if (raw.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) history.addAll(decoded);
        } catch (_) {}
      }
      history.add(result);
      entry['ancHistory'] = jsonEncode(history);
      final baseline = (result['ancBaseline'] as Map<String, dynamic>? ??
              const <String, dynamic>{})
          .map((k, v) => MapEntry(k, (v ?? '').toString()));
      entry['ancBaseline'] = jsonEncode(baseline);
    }
    final follow = _resolveFollowUpDate(form, result);
    _addRevisitEntry(
      individualId: (entry['individualId'] ?? '').toString(),
      memberName: (entry['fullName'] ?? '').toString(),
      formId: formId,
      formTitle: (result?['formTitle'] ?? form['title'] ?? '').toString(),
      followUpDate: follow,
    );
    _persistLocalState();
  }

  @override
  Widget build(BuildContext context) {
    if (!_stateLoaded) return const Center(child: CircularProgressIndicator());
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
            familyCount: _entries.length,
            entryLabel: 'Individual',
            onAddEntry: _addEntry,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _entries.isEmpty
                ? const Center(
                    child: Text('No individual entries yet. Click Add Entry to start.'),
                  )
                : ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final e = _entries[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            '${e['individualId'] ?? ''} | ${e['fullName'] ?? '-'}',
                          ),
                          subtitle: Text(
                            '${e['sex'] ?? '-'} | Age ${e['age'] ?? '-'} | '
                            'Phone ${e['contactPhone']?.isEmpty == true ? '-' : e['contactPhone']} | '
                            'Status ${e['status'] ?? 'Active'}\n'
                            'Location: ${e['location']?.isEmpty == true ? '-' : e['location']}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit Demography',
                                onPressed: () => _editEntry(index),
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                tooltip: 'Forms',
                                onPressed: () => _openFormList(
                                  assets: _assetsForEntry(e),
                                  entityLabel:
                                      '${e['fullName'] ?? ''} (${e['individualId'] ?? ''})',
                                  contextData: {
                                    'ancHistory': e['ancHistory'],
                                    'ancBaseline': e['ancBaseline'],
                                    'visitOptionsByFormId':
                                        _visitOptionsByFormIdForEntry(e),
                                  },
                                  onSelect: (form, result) {
                                    _handleFormResult(
                                      entry: e,
                                      form: form,
                                      result: result,
                                    );
                                    setState(() {});
                                  },
                                ),
                                icon: const Icon(Icons.article_outlined),
                              ),
                            ],
                          ),
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

class IndividualDataCollectionScreen extends StatefulWidget {
  const IndividualDataCollectionScreen({
    super.key,
    required this.samplingUnit,
    required this.setupData,
  });

  final String samplingUnit;
  final Map<String, String> setupData;

  @override
  State<IndividualDataCollectionScreen> createState() =>
      _IndividualDataCollectionScreenState();
}

class _IndividualDataCollectionScreenState
    extends State<IndividualDataCollectionScreen> {
  final GlobalKey<IndividualDataCollectionSectionState> _sectionKey =
      GlobalKey<IndividualDataCollectionSectionState>();

  void _openFollowUpDashboard() {
    final entries =
        _sectionKey.currentState?.getRevisitEntries() ?? const <Map<String, String>>[];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Individual Data Collection'),
        actions: [
          IconButton(
            onPressed: _openFollowUpDashboard,
            icon: const Icon(Icons.event_note_outlined),
            tooltip: 'Follow-ups',
          ),
          IconButton(
            onPressed: () async => _sectionKey.currentState?.uploadEntries(),
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Upload',
          ),
        ],
      ),
      body: IndividualDataCollectionSection(
        key: _sectionKey,
        samplingUnit: widget.samplingUnit,
        setupData: widget.setupData,
      ),
    );
  }
}
