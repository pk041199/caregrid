import 'package:flutter/material.dart';
import 'dart:convert';

class IndividualProfileScreen extends StatefulWidget {
  const IndividualProfileScreen({
    super.key,
    required this.member,
    required this.familyId,
    required this.familyMemberCount,
  });

  final Map<String, String> member;
  final String familyId;
  final int familyMemberCount;

  @override
  State<IndividualProfileScreen> createState() => _IndividualProfileScreenState();
}

class _IndividualProfileScreenState extends State<IndividualProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _kidsController;
  late final TextEditingController _clinicalNotesController;
  final List<_ComplaintEntryControllers> _complaintEntries = [];
  final PageController _complaintPageController = PageController();
  int _complaintPageIndex = 0;
  final List<_ComorbidityEntryControllers> _comorbidityEntries = [];
  final PageController _comorbidityPageController = PageController();
  int _comorbidityPageIndex = 0;
  final List<TextEditingController> _conditionControllers = [];
  final List<TextEditingController> _medicationControllers = [];
  final List<TextEditingController> _allergyControllers = [];
  final List<Map<String, TextEditingController>> _addonTreatmentRows = [];
  final List<Map<String, TextEditingController>> _addonInvestigationRows = [];
  late final TextEditingController _addonNotesController;

  String _pregnancyStatus = 'Not Applicable';
  String _hasNcd = 'No';
  String _tobaccoUse = 'No';
  String _alcoholUse = 'No';
  String _dietQuality = 'Mixed';
  String _occupationRisk = 'Low';
  String _mentalWellbeing = 'Stable';
  String _socialSupport = 'Good';

  bool get _isFemale =>
      (widget.member['sex'] ?? '').toLowerCase().trim() == 'female';
  int get _age => int.tryParse((widget.member['age'] ?? '').trim()) ?? 0;

  List<String> _decodeStringList(String raw, {String fallbackSingle = ''}) {
    final text = raw.trim();
    if (text.isEmpty) {
      if (fallbackSingle.trim().isEmpty) return const [];
      return [fallbackSingle.trim()];
    }
    try {
      final parsed = jsonDecode(text);
      if (parsed is List) {
        return parsed.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
    } catch (_) {}
    return text
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _initRepeatableList(
    List<TextEditingController> target,
    List<String> values,
  ) {
    if (values.isEmpty) {
      target.add(TextEditingController());
      return;
    }
    for (final value in values) {
      target.add(TextEditingController(text: value));
    }
  }

  @override
  void initState() {
    super.initState();
    _kidsController = TextEditingController(text: widget.member['numberOfKids'] ?? '');
    _clinicalNotesController = TextEditingController(
      text: widget.member['clinicalHistory'] ?? '',
    );
    _addonNotesController =
        TextEditingController(text: widget.member['profileAddonNotes'] ?? '');
    _initComplaintTimeline();
    _initComorbidityTimeline();
    _initRepeatableList(
      _conditionControllers,
      _decodeStringList(
        widget.member['knownConditionsList'] ?? '',
        fallbackSingle: widget.member['knownConditions'] ?? '',
      ),
    );
    _initRepeatableList(
      _medicationControllers,
      _decodeStringList(
        widget.member['currentMedicationsList'] ?? '',
        fallbackSingle: widget.member['currentMedications'] ?? '',
      ),
    );
    _initRepeatableList(
      _allergyControllers,
      _decodeStringList(
        widget.member['allergyHistoryList'] ?? '',
        fallbackSingle: widget.member['allergyHistory'] ?? '',
      ),
    );
    _pregnancyStatus = widget.member['pregnancyStatus'] ??
        (_isFemale ? 'Not Pregnant' : 'Not Applicable');
    _hasNcd = widget.member['hasNcd'] ?? 'No';
    _tobaccoUse = widget.member['tobaccoUse'] ?? 'No';
    _alcoholUse = widget.member['alcoholUse'] ?? 'No';
    _dietQuality = widget.member['dietQuality'] ?? 'Mixed';
    _occupationRisk = widget.member['occupationRisk'] ?? 'Low';
    _mentalWellbeing = widget.member['mentalWellbeing'] ?? 'Stable';
    _socialSupport = widget.member['socialSupport'] ?? 'Good';
    _initAddonRowsFromMember();
  }

  void _initAddonRowsFromMember() {
    List<Map<String, dynamic>> parseRows(String raw) {
      final text = raw.trim();
      if (text.isEmpty) return const [];
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
              .toList();
        }
      } catch (_) {}
      return const [];
    }

    final treatmentRows = parseRows(widget.member['profileAddonTreatments'] ?? '');
    if (treatmentRows.isEmpty) {
      _addonTreatmentRows.add({
        'medication': TextEditingController(),
        'dose': TextEditingController(),
        'frequency': TextEditingController(),
        'period': TextEditingController(),
      });
    } else {
      for (final row in treatmentRows) {
        _addonTreatmentRows.add({
          'medication':
              TextEditingController(text: (row['medication'] ?? '').toString()),
          'dose': TextEditingController(text: (row['dose'] ?? '').toString()),
          'frequency':
              TextEditingController(text: (row['frequency'] ?? '').toString()),
          'period': TextEditingController(text: (row['period'] ?? '').toString()),
        });
      }
    }

    final invRows = parseRows(widget.member['profileAddonInvestigations'] ?? '');
    if (invRows.isEmpty) {
      _addonInvestigationRows.add({
        'investigation': TextEditingController(),
        'frequency': TextEditingController(),
        'period': TextEditingController(),
      });
    } else {
      for (final row in invRows) {
        _addonInvestigationRows.add({
          'investigation': TextEditingController(
              text: (row['investigation'] ?? '').toString()),
          'frequency':
              TextEditingController(text: (row['frequency'] ?? '').toString()),
          'period': TextEditingController(text: (row['period'] ?? '').toString()),
        });
      }
    }
  }

  void _initComplaintTimeline() {
    final rawTimeline = (widget.member['presentingComplaintTimeline'] ?? '').trim();
    if (rawTimeline.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTimeline);
        if (decoded is List) {
          for (final entry in decoded) {
            if (entry is! Map) continue;
            final map = entry.map((k, v) => MapEntry(k.toString(), v));
            _complaintEntries.add(
              _ComplaintEntryControllers.fromMap(
                map,
                defaultDate: DateTime.now().toIso8601String().split('T').first,
              ),
            );
          }
        }
      } catch (_) {}
    }
    if (_complaintEntries.isNotEmpty) return;
    final oldComplaints = _decodeStringList(
      widget.member['presentingComplaints'] ?? '',
      fallbackSingle: widget.member['chiefComplaints'] ?? '',
    );
    if (oldComplaints.isNotEmpty) {
      for (final c in oldComplaints) {
        _complaintEntries.add(
          _ComplaintEntryControllers(
            entryDate: DateTime.now().toIso8601String().split('T').first,
            complaint: TextEditingController(text: c),
            duration: TextEditingController(),
            frequency: TextEditingController(),
            characteristics: [TextEditingController()],
            associatedSymptoms: [TextEditingController()],
          ),
        );
      }
    } else {
      _complaintEntries.add(_newComplaintEntry());
    }
  }

  _ComplaintEntryControllers _newComplaintEntry() {
    return _ComplaintEntryControllers(
      entryDate: DateTime.now().toIso8601String().split('T').first,
      complaint: TextEditingController(),
      duration: TextEditingController(),
      frequency: TextEditingController(),
      characteristics: [TextEditingController()],
      associatedSymptoms: [TextEditingController()],
    );
  }

  void _initComorbidityTimeline() {
    final rawTimeline = (widget.member['knownComorbidityTimeline'] ?? '').trim();
    if (rawTimeline.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTimeline);
        if (decoded is List) {
          for (final entry in decoded) {
            if (entry is! Map) continue;
            final map = entry.map((k, v) => MapEntry(k.toString(), v));
            _comorbidityEntries.add(
              _ComorbidityEntryControllers.fromMap(
                map,
                defaultDate: DateTime.now().toIso8601String().split('T').first,
              ),
            );
          }
        }
      } catch (_) {}
    }
    if (_comorbidityEntries.isNotEmpty) return;
    final knownConditions = _decodeStringList(
      widget.member['knownConditionsList'] ?? '',
      fallbackSingle: widget.member['knownConditions'] ?? '',
    );
    if (knownConditions.isNotEmpty) {
      for (final condition in knownConditions) {
        _comorbidityEntries.add(
          _ComorbidityEntryControllers(
            entryDate: DateTime.now().toIso8601String().split('T').first,
            selectedDisease: condition,
            otherDisease: TextEditingController(),
            duration: TextEditingController(),
            onTreatment: 'No',
            medications: [TextEditingController()],
            relatedComplaints: [TextEditingController()],
          ),
        );
      }
    } else {
      _comorbidityEntries.add(_newComorbidityEntry());
    }
  }

  _ComorbidityEntryControllers _newComorbidityEntry({
    String disease = '',
    String duration = '',
    String onTreatment = 'No',
    List<String> medications = const [],
    List<String> relatedComplaints = const [],
  }) {
    return _ComorbidityEntryControllers(
      entryDate: DateTime.now().toIso8601String().split('T').first,
      selectedDisease: disease,
      otherDisease: TextEditingController(),
      duration: TextEditingController(text: duration),
      onTreatment: onTreatment,
      medications: medications.isEmpty
          ? [TextEditingController()]
          : medications.map((e) => TextEditingController(text: e)).toList(),
      relatedComplaints: relatedComplaints.isEmpty
          ? [TextEditingController()]
          : relatedComplaints.map((e) => TextEditingController(text: e)).toList(),
    );
  }

  void _goToComorbidityPage(int delta) {
    final target = _comorbidityPageIndex + delta;
    if (target < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No past entry')),
      );
      return;
    }
    if (target >= _comorbidityEntries.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No next entry')),
      );
      return;
    }
    _comorbidityPageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _addComorbidityFollowupEntry() {
    final safeIndex =
        _comorbidityPageIndex.clamp(0, _comorbidityEntries.length - 1);
    final current = _comorbidityEntries[safeIndex];
    final next = _newComorbidityEntry(
      disease: current.selectedDisease,
      duration: current.duration.text.trim(),
      onTreatment: current.onTreatment,
      medications: current.medications.map((e) => e.text.trim()).toList(),
      relatedComplaints:
          current.relatedComplaints.map((e) => e.text.trim()).toList(),
    );
    setState(() {
      _comorbidityEntries.add(next);
      _comorbidityPageIndex = _comorbidityEntries.length - 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_comorbidityPageController.hasClients) return;
      _comorbidityPageController.animateToPage(
        _comorbidityPageIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _kidsController.dispose();
    _clinicalNotesController.dispose();
    _complaintPageController.dispose();
    _comorbidityPageController.dispose();
    for (final entry in _complaintEntries) {
      entry.dispose();
    }
    for (final entry in _comorbidityEntries) {
      entry.dispose();
    }
    for (final c in _conditionControllers) {
      c.dispose();
    }
    for (final c in _medicationControllers) {
      c.dispose();
    }
    for (final c in _allergyControllers) {
      c.dispose();
    }
    for (final row in _addonTreatmentRows) {
      for (final c in row.values) {
        c.dispose();
      }
    }
    for (final row in _addonInvestigationRows) {
      for (final c in row.values) {
        c.dispose();
      }
    }
    _addonNotesController.dispose();
    super.dispose();
  }

  List<String> _suggestedForms() {
    final list = <String>[];
    if (_isFemale && _pregnancyStatus == 'Pregnant') {
      list.add('anc');
    }
    if (_tobaccoUse == 'Yes' || _tobaccoUse == 'Past') {
      list.add('smoking_history');
    }
    if (_occupationRisk == 'High') {
      list.add('occupational_history');
    }
    if (_isFemale && _age >= 10) {
      list.add('reproductive_history');
      list.add('contraceptive_history');
    }
    return list;
  }

  List<String> _requiredAddonForms() {
    final required = <String>[];
    if (_tobaccoUse == 'Yes' || _tobaccoUse == 'Past') {
      required.add('smoking_history');
    }
    if (_occupationRisk == 'High' || _occupationRisk == 'Moderate') {
      required.add('occupational_history');
    }
    if (_isFemale && _age >= 15) {
      required.add('reproductive_history');
      required.add('contraceptive_history');
    }
    return required;
  }

  List<String> _collectValues(List<TextEditingController> controllers) {
    return controllers
        .map((c) => c.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<Map<String, String>> _collectRowValues(
    List<Map<String, TextEditingController>> rows,
  ) {
    final list = <Map<String, String>>[];
    for (final row in rows) {
      final mapped = row.map((k, v) => MapEntry(k, v.text.trim()));
      if (mapped.values.any((e) => e.isNotEmpty)) {
        list.add(mapped);
      }
    }
    return list;
  }

  void _saveAndContinue() {
    if (!_formKey.currentState!.validate()) return;

    final updated = Map<String, String>.from(widget.member);
    final complaints = _complaintEntries
        .map((e) => e.complaint.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final comorbList = _comorbidityEntries.map((e) => e.toMap()).toList();
    final conditions = _comorbidityEntries
        .map((e) => e.selectedDisease.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    final medications = _collectValues(_medicationControllers);
    final allergies = _collectValues(_allergyControllers);

    updated['numberOfKids'] = _kidsController.text.trim();
    updated['clinicalHistory'] = _clinicalNotesController.text.trim();
    updated['presentingComplaints'] = jsonEncode(complaints);
    updated['presentingComplaintTimeline'] =
        jsonEncode(_complaintEntries.map((e) => e.toMap()).toList());
    updated['knownConditionsList'] = jsonEncode(conditions);
    updated['knownComorbidityTimeline'] = jsonEncode(comorbList);
    updated['currentMedicationsList'] = jsonEncode(medications);
    updated['allergyHistoryList'] = jsonEncode(allergies);
    updated['chiefComplaints'] = complaints.join(' | ');
    updated['knownConditions'] = conditions.join(' | ');
    updated['currentMedications'] = medications.join(' | ');
    updated['allergyHistory'] = allergies.join(' | ');
    updated['pregnancyStatus'] = _pregnancyStatus;
    updated['hasNcd'] = _hasNcd;
    updated['tobaccoUse'] = _tobaccoUse;
    updated['alcoholUse'] = _alcoholUse;
    updated['dietQuality'] = _dietQuality;
    updated['occupationRisk'] = _occupationRisk;
    updated['mentalWellbeing'] = _mentalWellbeing;
    updated['socialSupport'] = _socialSupport;
    updated['profileAddonTreatments'] = jsonEncode(_collectRowValues(_addonTreatmentRows));
    updated['profileAddonInvestigations'] =
        jsonEncode(_collectRowValues(_addonInvestigationRows));
    updated['profileAddonNotes'] = _addonNotesController.text.trim();
    final hasComorbidity = conditions.isNotEmpty;
    _hasNcd = hasComorbidity ? 'Yes' : 'No';
    if (hasComorbidity) {
      updated['ncdActive'] = 'true';
    } else {
      updated['ncdActive'] = 'false';
    }

    Navigator.pop(context, {
      'member': updated,
      'suggestedFormIds': _suggestedForms(),
      'requiredAddonFormIds': _requiredAddonForms(),
      'openForms': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    final memberName = widget.member['fullName'] ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Individual Profile'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          Card(
            child: ListTile(
              title: Text(memberName.isEmpty ? 'Individual' : memberName),
              subtitle: Text(
                'Family: ${widget.familyId} | Sex: ${widget.member['sex'] ?? '-'} | Age: ${widget.member['age'] ?? '-'} | Family size: ${widget.familyMemberCount}',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Clinical Intake',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _buildComplaintTimelineSection(),
          const SizedBox(height: 12),
          _buildComorbidityTimelineSection(),
          const SizedBox(height: 12),
          _repeatableFieldGroup(
            title: 'Current medications',
            controllers: _medicationControllers,
            addLabel: 'Add medication',
          ),
          const SizedBox(height: 12),
          _repeatableFieldGroup(
            title: 'Allergy history',
            controllers: _allergyControllers,
            addLabel: 'Add allergy',
          ),
          const SizedBox(height: 16),
          const Text(
            'Clinico-social Profile',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _tobaccoUse,
            decoration: const InputDecoration(
              labelText: 'Tobacco use',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'No', child: Text('No')),
              DropdownMenuItem(value: 'Yes', child: Text('Yes')),
              DropdownMenuItem(value: 'Past', child: Text('Past')),
            ],
            onChanged: (value) => setState(() => _tobaccoUse = value ?? 'No'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _alcoholUse,
            decoration: const InputDecoration(
              labelText: 'Alcohol use',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'No', child: Text('No')),
              DropdownMenuItem(value: 'Occasional', child: Text('Occasional')),
              DropdownMenuItem(value: 'Regular', child: Text('Regular')),
            ],
            onChanged: (value) => setState(() => _alcoholUse = value ?? 'No'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _dietQuality,
            decoration: const InputDecoration(
              labelText: 'Diet quality',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Balanced', child: Text('Balanced')),
              DropdownMenuItem(value: 'Mixed', child: Text('Mixed')),
              DropdownMenuItem(value: 'Poor', child: Text('Poor')),
            ],
            onChanged: (value) =>
                setState(() => _dietQuality = value ?? 'Mixed'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _occupationRisk,
            decoration: const InputDecoration(
              labelText: 'Occupation/environment risk',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Low', child: Text('Low')),
              DropdownMenuItem(value: 'Moderate', child: Text('Moderate')),
              DropdownMenuItem(value: 'High', child: Text('High')),
            ],
            onChanged: (value) =>
                setState(() => _occupationRisk = value ?? 'Low'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _mentalWellbeing,
            decoration: const InputDecoration(
              labelText: 'Mental wellbeing',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Stable', child: Text('Stable')),
              DropdownMenuItem(value: 'Needs support', child: Text('Needs support')),
            ],
            onChanged: (value) =>
                setState(() => _mentalWellbeing = value ?? 'Stable'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _socialSupport,
            decoration: const InputDecoration(
              labelText: 'Family/social support',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Good', child: Text('Good')),
              DropdownMenuItem(value: 'Limited', child: Text('Limited')),
              DropdownMenuItem(value: 'None', child: Text('None')),
            ],
            onChanged: (value) =>
                setState(() => _socialSupport = value ?? 'Good'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Reproductive Profile',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _kidsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Number of children',
              helperText: 'Cannot exceed family size (${widget.familyMemberCount})',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final raw = (value ?? '').trim();
              if (raw.isEmpty) return null;
              final kids = int.tryParse(raw);
              if (kids == null || kids < 0) {
                return 'Enter a valid child count';
              }
              if (kids > widget.familyMemberCount) {
                return 'Child count cannot exceed family size';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          if (_isFemale)
            DropdownButtonFormField<String>(
              initialValue: _pregnancyStatus,
              decoration: const InputDecoration(
                labelText: 'Pregnancy status',
                border: OutlineInputBorder(),
              ),
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
              onChanged: (value) {
                setState(() {
                  _pregnancyStatus = value ?? 'Not Pregnant';
                });
              },
            )
          else
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Pregnancy status',
                border: OutlineInputBorder(),
              ),
              child: const Text('Not Applicable'),
            ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'NCD status',
              border: OutlineInputBorder(),
            ),
            child: Text(
              _comorbidityEntries.any((e) => e.selectedDisease.trim().isNotEmpty)
                  ? 'Yes (from Known Comorbidities)'
                  : 'No',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _clinicalNotesController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Additional notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Final Treatment (Read-only from Today Forms)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (widget.member['finalTreatmentReadonly'] ?? '').trim().isEmpty
                        ? '-'
                        : widget.member['finalTreatmentReadonly']!,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Final Investigation (Read-only)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (widget.member['finalInvestigationReadonly'] ?? '').trim().isEmpty
                        ? '-'
                        : widget.member['finalInvestigationReadonly']!,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Diagnosis / Advice (Read-only)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Diagnosis: ${(widget.member['finalDiagnosisReadonly'] ?? '-').toString()}\n'
                    'Advice: ${(widget.member['finalAdviceReadonly'] ?? '-').toString()}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _repeatableRowGroup(
            title: 'Add Other Treatment',
            rows: _addonTreatmentRows,
            fieldOrder: const ['medication', 'dose', 'frequency', 'period'],
            addLabel: 'Add Treatment',
          ),
          const SizedBox(height: 12),
          _repeatableRowGroup(
            title: 'Add Other Investigation',
            rows: _addonInvestigationRows,
            fieldOrder: const ['investigation', 'frequency', 'period'],
            addLabel: 'Add Investigation',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addonNotesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Final Notes and Advice (Add-on)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Suggested Forms',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _suggestedForms().isEmpty
                        ? 'No auto-suggested forms from current answers.'
                        : _suggestedForms().join(', ').toUpperCase(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _requiredAddonForms().isEmpty
                        ? 'No required add-on forms.'
                        : 'Required add-ons now: ${_requiredAddonForms().join(', ').toUpperCase()}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _saveAndContinue,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Save Profile & Continue to Forms'),
          ),
          ],
        ),
      ),
    );
  }

  Widget _repeatableFieldGroup({
    required String title,
    required List<TextEditingController> controllers,
    required String addLabel,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      controllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: Text(addLabel),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...controllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: '$title ${index + 1}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: controllers.length <= 1
                          ? null
                          : () {
                              setState(() {
                                final removed = controllers.removeAt(index);
                                removed.dispose();
                              });
                            },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _repeatableRowGroup({
    required String title,
    required List<Map<String, TextEditingController>> rows,
    required List<String> fieldOrder,
    required String addLabel,
  }) {
    Map<String, TextEditingController> newRow() {
      return {
        for (final key in fieldOrder) key: TextEditingController(),
      };
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => rows.add(newRow()));
                  },
                  icon: const Icon(Icons.add),
                  label: Text(addLabel),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...rows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('${title.split(' ').first} ${index + 1}'),
                          const Spacer(),
                          IconButton(
                            onPressed: rows.length <= 1
                                ? null
                                : () {
                                    setState(() {
                                      final removed = rows.removeAt(index);
                                      for (final c in removed.values) {
                                        c.dispose();
                                      }
                                    });
                                  },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                        ],
                      ),
                      ...fieldOrder.map((key) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextFormField(
                            controller: row[key],
                            decoration: InputDecoration(
                              labelText: key[0].toUpperCase() + key.substring(1),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintTimelineSection() {
    final safeIndex = _complaintPageIndex.clamp(0, _complaintEntries.length - 1);
    final currentDate = _complaintEntries.isEmpty
        ? DateTime.now().toIso8601String().split('T').first
        : _complaintEntries[safeIndex].entryDate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Presenting Complaint Timeline',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  currentDate,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 360,
              child: PageView.builder(
                controller: _complaintPageController,
                itemCount: _complaintEntries.length,
                onPageChanged: (i) => setState(() => _complaintPageIndex = i),
                itemBuilder: (context, index) {
                  final e = _complaintEntries[index];
                  Widget buildTextList({
                    required String title,
                    required List<TextEditingController> items,
                  }) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        ...items.asMap().entries.map((row) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: row.value,
                                    decoration: InputDecoration(
                                      labelText: '$title ${row.key + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: items.length <= 1
                                      ? null
                                      : () {
                                          setState(() {
                                            final removed = items.removeAt(row.key);
                                            removed.dispose();
                                          });
                                        },
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  }

                  return Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: e.complaint,
                              decoration: const InputDecoration(
                                labelText: 'Complaint',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: e.duration,
                                    decoration: const InputDecoration(
                                      labelText: 'Duration',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: e.frequency,
                                    decoration: const InputDecoration(
                                      labelText: 'Frequency',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        e.characteristics.add(TextEditingController());
                                      });
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Characteristic'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        e.associatedSymptoms.add(TextEditingController());
                                      });
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Assoc Symptom'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            buildTextList(
                              title: 'Characteristic',
                              items: e.characteristics,
                            ),
                            const SizedBox(height: 6),
                            buildTextList(
                              title: 'Assoc Symptom',
                              items: e.associatedSymptoms,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _complaintEntries.add(_newComplaintEntry());
                    _complaintPageIndex = _complaintEntries.length - 1;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_complaintPageController.hasClients) return;
                    _complaintPageController.animateToPage(
                      _complaintPageIndex,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  });
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Next Complaint'),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Swipe left/right to move between complaint entries.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComorbidityTimelineSection() {
    const diseaseOptions = <String>[
      '',
      'Diabetes',
      'Hypertension',
      'CKD',
      'IHD',
      'Stroke',
      'COPD',
      'Asthma',
      'Oral Cancer',
      'Breast Cancer',
      'Cervical Cancer',
      'Other',
    ];
    final safeIndex =
        _comorbidityPageIndex.clamp(0, _comorbidityEntries.length - 1);
    final currentDate = _comorbidityEntries.isEmpty
        ? DateTime.now().toIso8601String().split('T').first
        : _comorbidityEntries[safeIndex].entryDate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Known Comorbidities (NCD) Timeline',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  currentDate,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 420,
              child: PageView.builder(
                controller: _comorbidityPageController,
                itemCount: _comorbidityEntries.length,
                onPageChanged: (i) => setState(() => _comorbidityPageIndex = i),
                itemBuilder: (context, index) {
                  final e = _comorbidityEntries[index];
                  Widget buildTextList({
                    required String title,
                    required List<TextEditingController> items,
                  }) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        ...items.asMap().entries.map((row) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: row.value,
                                    decoration: InputDecoration(
                                      labelText: '$title ${row.key + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: items.length <= 1
                                      ? null
                                      : () {
                                          setState(() {
                                            final removed = items.removeAt(row.key);
                                            removed.dispose();
                                          });
                                        },
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  }

                  return Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: e.selectedDisease.isEmpty
                                  ? ''
                                  : e.selectedDisease,
                              decoration: const InputDecoration(
                                labelText: 'Disease',
                                border: OutlineInputBorder(),
                              ),
                              items: diseaseOptions
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d.isEmpty ? 'Select disease' : d),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  e.selectedDisease = value ?? '';
                                });
                              },
                            ),
                            if (e.selectedDisease == 'Other') ...[
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: e.otherDisease,
                                decoration: const InputDecoration(
                                  labelText: 'Other disease name',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: e.duration,
                                    decoration: const InputDecoration(
                                      labelText: 'Duration',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: e.onTreatment,
                                    decoration: const InputDecoration(
                                      labelText: 'On treatment',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'No', child: Text('No')),
                                      DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        e.onTreatment = value ?? 'No';
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        e.medications.add(TextEditingController());
                                      });
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Medication'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        e.relatedComplaints.add(TextEditingController());
                                      });
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Complaint'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            buildTextList(title: 'Medication', items: e.medications),
                            const SizedBox(height: 6),
                            buildTextList(
                              title: 'NCD Complaint',
                              items: e.relatedComplaints,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _goToComorbidityPage(-1),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Past'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _goToComorbidityPage(1),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _comorbidityEntries.add(_newComorbidityEntry());
                    _comorbidityPageIndex = _comorbidityEntries.length - 1;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_comorbidityPageController.hasClients) return;
                    _comorbidityPageController.animateToPage(
                      _comorbidityPageIndex,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  });
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Next Comorbidity'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addComorbidityFollowupEntry,
                icon: const Icon(Icons.schedule),
                label: const Text('Enter Follow-up for Current Comorbidity'),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Swipe right for past entry and left for next entry. If unavailable: No past entry / No next entry.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplaintEntryControllers {
  _ComplaintEntryControllers({
    required this.entryDate,
    required this.complaint,
    required this.duration,
    required this.frequency,
    required this.characteristics,
    required this.associatedSymptoms,
  });

  final String entryDate;
  final TextEditingController complaint;
  final TextEditingController duration;
  final TextEditingController frequency;
  final List<TextEditingController> characteristics;
  final List<TextEditingController> associatedSymptoms;

  factory _ComplaintEntryControllers.fromMap(
    Map<String, dynamic> map, {
    required String defaultDate,
  }) {
    List<TextEditingController> parseList(dynamic raw) {
      if (raw is List) {
        final values = raw
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (values.isEmpty) return [TextEditingController()];
        return values.map((e) => TextEditingController(text: e)).toList();
      }
      return [TextEditingController()];
    }

    return _ComplaintEntryControllers(
      entryDate: (map['entryDate'] ?? '').toString().trim().isEmpty
          ? defaultDate
          : (map['entryDate'] ?? '').toString(),
      complaint:
          TextEditingController(text: (map['complaint'] ?? '').toString()),
      duration: TextEditingController(text: (map['duration'] ?? '').toString()),
      frequency: TextEditingController(text: (map['frequency'] ?? '').toString()),
      characteristics: parseList(map['characteristics']),
      associatedSymptoms: parseList(map['associatedSymptoms']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entryDate': entryDate,
      'complaint': complaint.text.trim(),
      'duration': duration.text.trim(),
      'frequency': frequency.text.trim(),
      'characteristics': characteristics
          .map((e) => e.text.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      'associatedSymptoms': associatedSymptoms
          .map((e) => e.text.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    };
  }

  void dispose() {
    complaint.dispose();
    duration.dispose();
    frequency.dispose();
    for (final c in characteristics) {
      c.dispose();
    }
    for (final c in associatedSymptoms) {
      c.dispose();
    }
  }
}

class _ComorbidityEntryControllers {
  _ComorbidityEntryControllers({
    required this.entryDate,
    required this.selectedDisease,
    required this.otherDisease,
    required this.duration,
    required this.onTreatment,
    required this.medications,
    required this.relatedComplaints,
  });

  final String entryDate;
  String selectedDisease;
  final TextEditingController otherDisease;
  final TextEditingController duration;
  String onTreatment;
  final List<TextEditingController> medications;
  final List<TextEditingController> relatedComplaints;

  factory _ComorbidityEntryControllers.fromMap(
    Map<String, dynamic> map, {
    required String defaultDate,
  }) {
    List<TextEditingController> parseList(dynamic raw) {
      if (raw is List) {
        final values = raw
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (values.isEmpty) return [TextEditingController()];
        return values.map((e) => TextEditingController(text: e)).toList();
      }
      return [TextEditingController()];
    }

    return _ComorbidityEntryControllers(
      entryDate: (map['entryDate'] ?? '').toString().trim().isEmpty
          ? defaultDate
          : (map['entryDate'] ?? '').toString(),
      selectedDisease: (map['disease'] ?? '').toString(),
      otherDisease:
          TextEditingController(text: (map['otherDisease'] ?? '').toString()),
      duration: TextEditingController(text: (map['duration'] ?? '').toString()),
      onTreatment: (map['onTreatment'] ?? 'No').toString(),
      medications: parseList(map['medications']),
      relatedComplaints: parseList(map['relatedComplaints']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entryDate': entryDate,
      'disease': selectedDisease.trim(),
      'otherDisease': otherDisease.text.trim(),
      'duration': duration.text.trim(),
      'onTreatment': onTreatment,
      'medications': medications
          .map((e) => e.text.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      'relatedComplaints': relatedComplaints
          .map((e) => e.text.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    };
  }

  void dispose() {
    otherDisease.dispose();
    duration.dispose();
    for (final c in medications) {
      c.dispose();
    }
    for (final c in relatedComplaints) {
      c.dispose();
    }
  }
}
