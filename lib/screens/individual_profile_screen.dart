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
  final List<TextEditingController> _complaintControllers = [];
  final List<TextEditingController> _conditionControllers = [];
  final List<TextEditingController> _medicationControllers = [];
  final List<TextEditingController> _allergyControllers = [];

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
    _initRepeatableList(
      _complaintControllers,
      _decodeStringList(
        widget.member['presentingComplaints'] ?? '',
        fallbackSingle: widget.member['chiefComplaints'] ?? '',
      ),
    );
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
  }

  @override
  void dispose() {
    _kidsController.dispose();
    _clinicalNotesController.dispose();
    for (final c in _complaintControllers) {
      c.dispose();
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
    super.dispose();
  }

  List<String> _suggestedForms() {
    final list = <String>[];
    if (_isFemale && _pregnancyStatus == 'Pregnant') {
      list.add('anc');
    }
    if (_hasNcd == 'Yes') {
      list.add('ncd');
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

  void _saveAndContinue() {
    if (!_formKey.currentState!.validate()) return;

    final updated = Map<String, String>.from(widget.member);
    final complaints = _collectValues(_complaintControllers);
    final conditions = _collectValues(_conditionControllers);
    final medications = _collectValues(_medicationControllers);
    final allergies = _collectValues(_allergyControllers);

    updated['numberOfKids'] = _kidsController.text.trim();
    updated['clinicalHistory'] = _clinicalNotesController.text.trim();
    updated['presentingComplaints'] = jsonEncode(complaints);
    updated['knownConditionsList'] = jsonEncode(conditions);
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
    if (_hasNcd == 'Yes') {
      updated['ncdActive'] = 'true';
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
          _repeatableFieldGroup(
            title: 'Presenting complaints',
            controllers: _complaintControllers,
            addLabel: 'Add complaint',
          ),
          const SizedBox(height: 12),
          _repeatableFieldGroup(
            title: 'Known conditions (HTN/DM/asthma/etc.)',
            controllers: _conditionControllers,
            addLabel: 'Add condition',
          ),
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
          DropdownButtonFormField<String>(
            initialValue: _hasNcd,
            decoration: const InputDecoration(
              labelText: 'Any NCD condition?',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'No', child: Text('No')),
              DropdownMenuItem(value: 'Yes', child: Text('Yes')),
            ],
            onChanged: (value) {
              setState(() {
                _hasNcd = value ?? 'No';
              });
            },
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
}
