import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FormViewerScreen extends StatefulWidget {
  const FormViewerScreen({
    super.key,
    required this.assetPath,
    this.entityLabel,
    this.contextData,
  });

  final String assetPath;
  final String? entityLabel;
  final Map<String, dynamic>? contextData;

  @override
  State<FormViewerScreen> createState() => _FormViewerScreenState();
}

class _FormViewerScreenState extends State<FormViewerScreen> {
  Map<String, dynamic>? _form;
  bool _loading = true;
  String? _error;

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _selectValues = {};
  String _followUpDate = '';

  // ANC-specific
  String _ancVisitType = 'First';
  final TextEditingController _picme = TextEditingController();
  final TextEditingController _maritalHistory = TextEditingController();
  final TextEditingController _consanguinity = TextEditingController();
  final TextEditingController _lastChildBirthType = TextEditingController();
  final TextEditingController _lscsIndication = TextEditingController();
  final TextEditingController _menstrualHistory = TextEditingController();
  final TextEditingController _lmp = TextEditingController();
  final TextEditingController _edd = TextEditingController();
  final TextEditingController _gaWeeks = TextEditingController();
  final TextEditingController _trimester = TextEditingController();
  final TextEditingController _totalAncVisits = TextEditingController(text: '1');
  final TextEditingController _gpla = TextEditingController();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _weightGain = TextEditingController();
  final TextEditingController _generalExam = TextEditingController();
  final TextEditingController _abdominalExam = TextEditingController();
  final TextEditingController _bloodTransfusion = TextEditingController();
  final TextEditingController _immunizationDose = TextEditingController();
  final TextEditingController _supplementDose = TextEditingController();
  final List<TextEditingController> _complaints = [];
  final List<TextEditingController> _coMorbid = [];
  final List<Map<String, TextEditingController>> _previousChildForms = [];
  final List<Map<String, TextEditingController>> _systemExams = [];
  bool _negativeComplaints = false;
  bool _immunizationGiven = true;
  bool _supplementsGiven = true;
  String _investigationSummary = '';
  String _scanSummary = '';
  List<String> _saveSuggestions = [];
  int _ancHistoryCount = 0;
  Map<String, String> _ancBaseline = {};
  Map<String, dynamic>? _lastAncVisit;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _picme.dispose();
    _maritalHistory.dispose();
    _consanguinity.dispose();
    _lastChildBirthType.dispose();
    _lscsIndication.dispose();
    _menstrualHistory.dispose();
    _lmp.dispose();
    _edd.dispose();
    _gaWeeks.dispose();
    _trimester.dispose();
    _totalAncVisits.dispose();
    _gpla.dispose();
    _height.dispose();
    _weight.dispose();
    _weightGain.dispose();
    _generalExam.dispose();
    _abdominalExam.dispose();
    _bloodTransfusion.dispose();
    _immunizationDose.dispose();
    _supplementDose.dispose();
    for (final c in _complaints) {
      c.dispose();
    }
    for (final c in _coMorbid) {
      c.dispose();
    }
    for (final child in _previousChildForms) {
      for (final c in child.values) {
        c.dispose();
      }
    }
    for (final exam in _systemExams) {
      for (final c in exam.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  bool get _isAnc => (_form?['id'] ?? '').toString() == 'anc';

  Future<void> _loadForm() async {
    try {
      final jsonStr = await rootBundle.loadString(widget.assetPath);
      final data = jsonDecode(jsonStr);
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid form JSON');
      }
      _form = data;
      _loadAncContext();
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _loadAncContext() {
    if (!_isAnc) return;
    final parsedHistory = _readAncHistory();
    _ancHistoryCount = parsedHistory.length;
    if (parsedHistory.isNotEmpty) {
      final last = parsedHistory.last;
      if (last is Map<String, dynamic>) _lastAncVisit = last;
    }
    final rawBaseline = (widget.contextData?['ancBaseline'] ?? '').toString();
    if (rawBaseline.isNotEmpty) {
      try {
        final map = jsonDecode(rawBaseline);
        if (map is Map<String, dynamic>) {
          _ancBaseline = map.map((k, v) => MapEntry(k, (v ?? '').toString()));
        }
      } catch (_) {}
    }
    _complaints.add(TextEditingController());
    _coMorbid.add(TextEditingController());

    if (_ancHistoryCount > 0) {
      _ancVisitType = 'Follow-up';
      _lmp.text = _ancBaseline['lmp'] ?? '';
      _gpla.text = _ancBaseline['gpla'] ?? '';
      _picme.text = _ancBaseline['picme'] ?? '';
      _maritalHistory.text = _ancBaseline['maritalHistory'] ?? '';
      _consanguinity.text = _ancBaseline['consanguinity'] ?? '';
      _menstrualHistory.text = _ancBaseline['menstrualHistory'] ?? '';
      _height.text = _ancBaseline['height'] ?? '';
      _totalAncVisits.text = (_ancHistoryCount + 1).toString();
      _computeFromLmp();
      _prefillFromLastVisit();
    } else {
      _totalAncVisits.text = '1';
    }
    _refreshAncRecommendations();
  }

  List<dynamic> _readAncHistory() {
    final raw = widget.contextData?['ancHistory'];
    if (raw is List<dynamic>) return raw;
    final rawText = (raw ?? '').toString().trim();
    if (rawText.isEmpty) return const [];
    try {
      final decoded = jsonDecode(rawText);
      if (decoded is List<dynamic>) return decoded;
    } catch (_) {}
    return const [];
  }

  void _prefillFromLastVisit() {
    final values = (_lastAncVisit?['values'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    _weight.text = (values['weight'] ?? '').toString();
    _bloodTransfusion.text = (values['bloodTransfusion'] ?? '').toString();
  }

  void _refreshAncRecommendations() {
    final weeks = int.tryParse(_gaWeeks.text.trim()) ?? 0;
    final suggestions = <String>[];
    final investigations = <String>[];
    final scans = <String>[];

    if (weeks <= 13) {
      investigations.add('Baseline ANC labs expected.');
      scans.add('Dating scan / NT scan window.');
    } else if (weeks <= 27) {
      investigations.add('Repeat Hb and urine checks expected.');
      investigations.add('GDM screening around 24-28 weeks.');
      scans.add('TIFFA scan expected (around 18-22 weeks).');
    } else {
      investigations.add('Third trimester Hb and urine checks expected.');
      scans.add('Growth scan expected.');
    }

    if (!_immunizationGiven) {
      suggestions.add('Immunization not given. Counsel and document reason.');
    }
    if (!_supplementsGiven) {
      suggestions.add('Supplements not given. Counsel and document reason.');
    }
    if (_scanSummary.trim().isEmpty) {
      suggestions.add('Scan findings not entered. Add done/not done details.');
    }
    if (_investigationSummary.trim().isEmpty) {
      suggestions.add('Investigation summary missing for this visit.');
    }

    setState(() {
      _saveSuggestions = suggestions;
      _investigationSummary = investigations.join(' ');
      _scanSummary = scans.join(' ');
    });
  }

  void _computeFromLmp() {
    final lmp = DateTime.tryParse(_lmp.text.trim());
    if (lmp == null) return;
    final today = DateTime.now();
    final weeks = (today.difference(lmp).inDays / 7).floor().clamp(0, 45);
    _gaWeeks.text = weeks.toString();
    if (weeks <= 13) {
      _trimester.text = 'I';
    } else if (weeks <= 27) {
      _trimester.text = 'II';
    } else {
      _trimester.text = 'III';
    }
    _edd.text = lmp.add(const Duration(days: 280)).toIso8601String().split('T').first;
  }

  void _addPreviousChildForm() {
    setState(() {
      _previousChildForms.add({
        'term': TextEditingController(),
        'delayFromEdd': TextEditingController(),
        'deliveryType': TextEditingController(),
        'babyHistory': TextEditingController(),
        'nicu': TextEditingController(),
        'jaundice': TextEditingController(),
        'meconium': TextEditingController(),
        'progress': TextEditingController(),
        'induction': TextEditingController(),
        'lscsPostOp': TextEditingController(),
      });
    });
  }

  void _addSystemExam() {
    setState(() {
      _systemExams.add({
        'system': TextEditingController(),
        'finding': TextEditingController(),
      });
    });
  }

  Future<void> _pickDate(TextEditingController controller, {VoidCallback? then}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    controller.text = picked.toIso8601String().split('T').first;
    then?.call();
  }

  Widget _buildGenericField(Map<String, dynamic> field) {
    final id = (field['id'] ?? '').toString();
    final label = (field['label'] ?? id).toString();
    final type = (field['type'] ?? 'text').toString();
    final options = (field['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];

    if (type == 'select') {
      return DropdownButtonFormField<String>(
        initialValue: _selectValues[id],
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => setState(() => _selectValues[id] = v),
        decoration: InputDecoration(labelText: label),
      );
    }
    final c = _controllers[id] ??= TextEditingController();
    return TextFormField(
      controller: c,
      readOnly: type == 'date',
      onTap: type == 'date' ? () => _pickDate(c) : null,
      keyboardType: type == 'number' ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
    );
  }

  Map<String, dynamic> _buildAncResult() {
    final complaints = _negativeComplaints
        ? <String>['Negative']
        : _complaints.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();
    final coMorbid = _coMorbid.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();
    final previousChildren = _previousChildForms
        .map((child) => child.map((k, v) => MapEntry(k, v.text.trim())))
        .where((child) => child.values.any((v) => v.isNotEmpty))
        .toList();
    final systemExam = _systemExams
        .map((exam) => exam.map((k, v) => MapEntry(k, v.text.trim())))
        .where((exam) => exam.values.any((v) => v.isNotEmpty))
        .toList();
    final resolvedFollow = _followUpDate.trim().isNotEmpty
        ? _followUpDate.trim()
        : DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T').first;
    return {
      'formId': 'anc',
      'formTitle': (_form?['title'] ?? 'ANC').toString(),
      'followUpDate': resolvedFollow,
      'values': {
        'visitType': _ancVisitType,
        'picme': _picme.text.trim(),
        'maritalHistory': _maritalHistory.text.trim(),
        'consanguinity': _consanguinity.text.trim(),
        'lastChildBirthType': _lastChildBirthType.text.trim(),
        'lscsIndication': _lscsIndication.text.trim(),
        'menstrualHistory': _menstrualHistory.text.trim(),
        'lmp': _lmp.text.trim(),
        'edd': _edd.text.trim(),
        'gaWeeks': _gaWeeks.text.trim(),
        'trimester': _trimester.text.trim(),
        'totalAncVisits': _totalAncVisits.text.trim(),
        'gpla': _gpla.text.trim(),
        'height': _height.text.trim(),
        'weight': _weight.text.trim(),
        'weightGain': _weightGain.text.trim(),
        'generalExam': _generalExam.text.trim(),
        'abdominalExam': _abdominalExam.text.trim(),
        'bloodTransfusion': _bloodTransfusion.text.trim(),
        'investigationSummary': _investigationSummary.trim(),
        'scanSummary': _scanSummary.trim(),
        'immunizationGiven': _immunizationGiven ? 'Yes' : 'No',
        'supplementsGiven': _supplementsGiven ? 'Yes' : 'No',
        'immunizationDose': _immunizationDose.text.trim(),
        'supplementDose': _supplementDose.text.trim(),
        'complaints': complaints,
        'coMorbidities': coMorbid,
        'previousChildren': previousChildren,
        'systemExamination': systemExam,
        'saveSuggestions': _saveSuggestions,
      },
      'ancBaseline': {
        'lmp': _lmp.text.trim(),
        'gpla': _gpla.text.trim(),
        'picme': _picme.text.trim(),
        'maritalHistory': _maritalHistory.text.trim(),
        'consanguinity': _consanguinity.text.trim(),
        'menstrualHistory': _menstrualHistory.text.trim(),
        'height': _height.text.trim(),
      }
    };
  }

  void _save() {
    if (_isAnc) {
      Navigator.pop(context, _buildAncResult());
      return;
    }
    final values = <String, String>{};
    for (final e in _controllers.entries) {
      values[e.key] = e.value.text.trim();
    }
    for (final e in _selectValues.entries) {
      values[e.key] = (e.value ?? '').trim();
    }
    final resolvedFollow = _followUpDate.isNotEmpty
        ? _followUpDate
        : (values['next_visit_date'] ?? values['follow_up_date'] ?? '');
    Navigator.pop(context, {
      'formId': (_form?['id'] ?? '').toString(),
      'formTitle': (_form?['title'] ?? 'Form').toString(),
      'values': values,
      'followUpDate': resolvedFollow,
    });
  }

  Widget _buildAncClinicalRangeGuide() {
    const rows = <Map<String, String>>[
      {
        'label': 'Hemoglobin (g/dL)',
        'low': '< 11 (Anemia)',
        'normal': '11 - 13.5',
        'high': '> 13.5 (Hemoconcentration/dehydration possibility)',
      },
      {
        'label': 'Blood Pressure (mmHg)',
        'low': '< 90/60 (Hypotension)',
        'normal': '90/60 to 139/89',
        'high': '>= 140/90 (Hypertension in pregnancy)',
      },
      {
        'label': 'Fasting Plasma Glucose (mg/dL)',
        'low': '< 70 (Hypoglycemia)',
        'normal': '70 - 94',
        'high': '>= 95 (GDM risk)',
      },
      {
        'label': 'Random Plasma Glucose (mg/dL)',
        'low': '< 70',
        'normal': '70 - 139',
        'high': '>= 140 (Abnormal; evaluate further)',
      },
      {
        'label': 'Weight Gain',
        'low': 'Lower than expected by trimester',
        'normal': 'Steady trimester-appropriate gain',
        'high': 'Excessive gain; assess edema/PIH risk',
      },
    ];

    Widget valueCell(String text, Color color) {
      return Expanded(
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: 12),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clinical Interpretation Guide (Low / Normal / High)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...rows.map((r) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['label'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        valueCell('Low: ${r['low']}', Colors.red.shade700),
                        const SizedBox(width: 8),
                        valueCell('Normal: ${r['normal']}', Colors.green.shade700),
                        const SizedBox(width: 8),
                        valueCell('High: ${r['high']}', Colors.orange.shade800),
                      ],
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

  Widget _buildAnc() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _ancVisitType,
          items: const [
            DropdownMenuItem(value: 'First', child: Text('First Visit')),
            DropdownMenuItem(value: 'Follow-up', child: Text('Follow-up')),
          ],
          onChanged: (v) => setState(() => _ancVisitType = v ?? 'First'),
          decoration: const InputDecoration(labelText: 'ANC Visit'),
        ),
        const SizedBox(height: 8),
        TextFormField(controller: _picme, decoration: const InputDecoration(labelText: 'PICME Number')),
        const SizedBox(height: 8),
        TextFormField(
          controller: _lmp,
          readOnly: _ancVisitType == 'Follow-up' && _lmp.text.trim().isNotEmpty,
          onTap: () => _pickDate(_lmp, then: () {
            _computeFromLmp();
            _refreshAncRecommendations();
          }),
          decoration: InputDecoration(
            labelText: 'LMP',
            helperText: _ancVisitType == 'Follow-up' ? 'Retrieved from previous visit when available' : null,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(controller: _gaWeeks, readOnly: true, decoration: const InputDecoration(labelText: 'Gestation Weeks')),
        const SizedBox(height: 8),
        TextFormField(controller: _trimester, readOnly: true, decoration: const InputDecoration(labelText: 'Trimester')),
        const SizedBox(height: 8),
        TextFormField(controller: _edd, readOnly: true, decoration: const InputDecoration(labelText: 'EDD')),
        const SizedBox(height: 8),
        TextFormField(controller: _totalAncVisits, readOnly: true, decoration: const InputDecoration(labelText: 'Total ANC Visits')),
        if (_ancVisitType == 'First') ...[
          const SizedBox(height: 8),
          TextFormField(controller: _gpla, decoration: const InputDecoration(labelText: 'GPLA (First visit only)')),
          const SizedBox(height: 8),
          TextFormField(
            controller: _maritalHistory,
            decoration: const InputDecoration(labelText: 'Marital History'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _consanguinity,
            decoration: const InputDecoration(labelText: 'Consanguinity'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _lastChildBirthType,
            decoration: const InputDecoration(labelText: 'Last Childbirth (Normal/LSCS)'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _lscsIndication,
            decoration: const InputDecoration(labelText: 'If LSCS, Indication'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _menstrualHistory,
            decoration: const InputDecoration(labelText: 'Menstrual History'),
          ),
        ],
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          onTap: () async {
            final temp = TextEditingController(text: _followUpDate);
            await _pickDate(temp);
            setState(() => _followUpDate = temp.text.trim());
            temp.dispose();
          },
          decoration: InputDecoration(
            labelText: 'Follow-up Date',
            hintText: _followUpDate.isEmpty ? 'Select date' : _followUpDate,
            suffixIcon: const Icon(Icons.calendar_today),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Presenting Complaints', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _negativeComplaints = !_negativeComplaints),
              child: Text(_negativeComplaints ? 'Negative' : 'Mark Negative'),
            ),
            OutlinedButton(onPressed: _negativeComplaints ? null : () => setState(() => _complaints.add(TextEditingController())), child: const Text('Add')),
          ],
        ),
        if (!_negativeComplaints)
          ..._complaints.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextFormField(controller: c, decoration: const InputDecoration(labelText: 'Complaint')),
              )),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Co-morbidities', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            OutlinedButton(onPressed: () => setState(() => _coMorbid.add(TextEditingController())), child: const Text('Add')),
          ],
        ),
        ..._coMorbid.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextFormField(controller: c, decoration: const InputDecoration(labelText: 'Co-morbidity')),
            )),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Previous Child Gestation History',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            OutlinedButton(onPressed: _addPreviousChildForm, child: const Text('Add')),
          ],
        ),
        ..._previousChildForms.asMap().entries.map((entry) {
          final i = entry.key + 1;
          final child = entry.value;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Child $i'),
                  TextFormField(
                    controller: child['term'],
                    decoration: const InputDecoration(labelText: 'Term/Preterm'),
                  ),
                  TextFormField(
                    controller: child['delayFromEdd'],
                    decoration: const InputDecoration(labelText: 'Delay from EDD'),
                  ),
                  TextFormField(
                    controller: child['deliveryType'],
                    decoration: const InputDecoration(labelText: 'Type of Delivery'),
                  ),
                  TextFormField(
                    controller: child['babyHistory'],
                    decoration: const InputDecoration(labelText: 'Baby cried / baby history'),
                  ),
                  TextFormField(
                    controller: child['nicu'],
                    decoration: const InputDecoration(labelText: 'NICU Admission'),
                  ),
                  TextFormField(
                    controller: child['jaundice'],
                    decoration: const InputDecoration(labelText: 'Neonatal Jaundice'),
                  ),
                  TextFormField(
                    controller: child['meconium'],
                    decoration: const InputDecoration(labelText: 'Meconium Aspiration'),
                  ),
                  TextFormField(
                    controller: child['progress'],
                    decoration: const InputDecoration(labelText: 'Progress'),
                  ),
                  TextFormField(
                    controller: child['induction'],
                    decoration: const InputDecoration(labelText: 'Induction'),
                  ),
                  TextFormField(
                    controller: child['lscsPostOp'],
                    decoration: const InputDecoration(labelText: 'Post-op history if LSCS'),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        if (_ancVisitType == 'First')
          TextFormField(controller: _height, decoration: const InputDecoration(labelText: 'Height (First visit)')),
        const SizedBox(height: 8),
        TextFormField(controller: _weight, decoration: const InputDecoration(labelText: 'Weight')),
        if (_ancVisitType == 'Follow-up') ...[
          const SizedBox(height: 8),
          TextFormField(controller: _weightGain, decoration: const InputDecoration(labelText: 'Weight Gain (Follow-up)')),
        ],
        const SizedBox(height: 8),
        TextFormField(
          controller: _generalExam,
          decoration: const InputDecoration(
            labelText: 'General Examination (+/-)',
            hintText: 'Pallor+, Icterus-, Edema+',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _abdominalExam,
          decoration: const InputDecoration(
            labelText: 'Abdominal Examination (ANC specific)',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('System Examination', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            OutlinedButton(onPressed: _addSystemExam, child: const Text('Add')),
          ],
        ),
        ..._systemExams.map((exam) => Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: exam['system'],
                    decoration: const InputDecoration(labelText: 'System'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: exam['finding'],
                    decoration: const InputDecoration(labelText: 'Finding (+/-)'),
                  ),
                ),
              ],
            )),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bloodTransfusion,
          decoration: const InputDecoration(labelText: 'Blood Transfusion History'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _investigationSummary,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Investigation Guidance (By Gestational Age)',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _scanSummary,
          readOnly: true,
          decoration: const InputDecoration(labelText: 'Scan Guidance'),
        ),
        const SizedBox(height: 8),
        _buildAncClinicalRangeGuide(),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Immunization Given'),
          value: _immunizationGiven,
          onChanged: (v) {
            _immunizationGiven = v;
            _refreshAncRecommendations();
          },
        ),
        TextFormField(
          controller: _immunizationDose,
          decoration: const InputDecoration(labelText: 'Immunization Dose / Taken details'),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Supplements Given'),
          value: _supplementsGiven,
          onChanged: (v) {
            _supplementsGiven = v;
            _refreshAncRecommendations();
          },
        ),
        TextFormField(
          controller: _supplementDose,
          decoration: const InputDecoration(labelText: 'Supplement dose / Taken details'),
        ),
        if (_saveSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Save Suggestions',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  ..._saveSuggestions.map((e) => Text('- $e')),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save ANC')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = (_form?['sections'] as List<dynamic>?) ?? const [];
    final title = (_form?['title'] ?? 'Form').toString();
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text('Failed to load form: $_error')));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: _isAnc
          ? _buildAnc()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sections.length + 1,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == sections.length) {
                  return ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Form'),
                  );
                }
                final section = sections[index] as Map<String, dynamic>;
                final fields = (section['fields'] as List<dynamic>?) ?? const [];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((section['title'] ?? section['id'] ?? '').toString(),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...fields.map((f) {
                          if (f is! Map<String, dynamic>) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildGenericField(f),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
