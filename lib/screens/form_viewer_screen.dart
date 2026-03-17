import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/device_integration_service.dart';
import '../services/auth_service.dart';
import '../services/medical_role_policy.dart';

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
  final Map<String, String> _draftGenericTexts = {};
  final Map<String, String?> _draftGenericSelects = {};
  String _followUpDate = '';
  bool _addFollowUp = false;
  String _userRole = '';
  final Map<String, List<TextEditingController>> _repeatableTextControllers = {};
  final Map<String, List<Map<String, dynamic>>> _repeatableGroupControllers = {};
  final Map<String, Set<String>> _multiSelectValues = {};
  Timer? _draftTimer;

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
  final DeviceIntegrationService _deviceService =
      DeviceIntegrationService.instance;
  final AuthService _authService = AuthService();
  StreamSubscription<DeviceReading>? _ecgSub;
  StreamSubscription<DeviceReading>? _pftSub;
  StreamSubscription<DeviceReading>? _stethSub;
  String _ecgLive = '';
  String _pftLive = '';
  String _stethLive = '';
  int _activeSectionIndex = 0;

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
    for (final list in _repeatableTextControllers.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    for (final rows in _repeatableGroupControllers.values) {
      for (final row in rows) {
        for (final value in row.values) {
          if (value is TextEditingController) {
            value.dispose();
          } else if (value is List<TextEditingController>) {
            for (final c in value) {
              c.dispose();
            }
          }
        }
      }
    }
    _ecgSub?.cancel();
    _pftSub?.cancel();
    _stethSub?.cancel();
    _deviceService.disconnect(DeviceType.ecg);
    _deviceService.disconnect(DeviceType.pft);
    _deviceService.disconnect(DeviceType.steth);
    _draftTimer?.cancel();
    super.dispose();
  }

  bool get _isAnc => (_form?['id'] ?? '').toString() == 'anc';
  bool get _isMachineConnect =>
      (_form?['id'] ?? '').toString() == 'machine_connect_examination';
  bool get _isClinicalNcd =>
      (_form?['id'] ?? '').toString() == 'clinical_history_ncd';
  bool get _isDoctor =>
      _userRole.toLowerCase().contains('doctor');
  bool get _followUpEnabled {
    final follow = _form?['followup'];
    return follow is Map<String, dynamic> && follow['enabled'] == true;
  }

  int? get _followUpCycleDays {
    final follow = _form?['followup'];
    if (follow is! Map<String, dynamic>) return null;
    return int.tryParse((follow['defaultCycleDays'] ?? '').toString());
  }

  Future<void> _loadForm() async {
    try {
      _userRole = _authService.currentUserRole ?? '';
      final jsonStr = await rootBundle.loadString(widget.assetPath);
      final data = jsonDecode(jsonStr);
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid form JSON');
      }
      _form = data;
      if (_isMachineConnect) {
        _ecgSub = _deviceService.readings(DeviceType.ecg).listen((r) {
          if (!mounted) return;
          setState(() => _ecgLive = r.summary);
        });
        _pftSub = _deviceService.readings(DeviceType.pft).listen((r) {
          if (!mounted) return;
          setState(() => _pftLive = r.summary);
        });
        _stethSub = _deviceService.readings(DeviceType.steth).listen((r) {
          if (!mounted) return;
          setState(() => _stethLive = r.summary);
        });
      }
      if (_followUpEnabled || (_followUpCycleDays ?? 0) > 0 || _isAnc) {
        _addFollowUp = true;
      }
      _loadAncContext();
      _prefillClinicalNcdFromHistory();
      await _loadDraft();
      if (_addFollowUp &&
          _followUpDate.trim().isEmpty &&
          (_followUpCycleDays ?? 0) > 0) {
        _followUpDate = DateTime.now()
            .add(Duration(days: _followUpCycleDays!))
            .toIso8601String()
            .split('T')
            .first;
      }
      if (_isAnc && _addFollowUp && _followUpDate.trim().isEmpty) {
        _followUpDate = DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String()
            .split('T')
            .first;
      }
      setState(() => _loading = false);
      _startDraftAutoSave();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _prefillClinicalNcdFromHistory() {
    if (!_isClinicalNcd) return;
    final raw = widget.contextData?['previousEntries'];
    if (raw is! List || raw.isEmpty) return;
    final entries = raw
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
    if (entries.isEmpty) return;
    final latest = entries.last;
    final latestValuesRaw = latest['values'];
    Map<String, dynamic> latestValues = const {};
    if (latestValuesRaw is Map) {
      latestValues = latestValuesRaw.map((k, v) => MapEntry(k.toString(), v));
    }
    if (latestValues.isEmpty) return;
    for (final entry in latestValues.entries) {
      final def = _findFieldDefinition(entry.key);
      if (def == null) continue;
      final type = (def['type'] ?? 'text').toString();
      if (type == 'select') {
        final val = entry.value?.toString().trim() ?? '';
        if (val.isNotEmpty) _selectValues[entry.key] = val;
        continue;
      }
      if (type == 'multiselect') {
        final vals = _decodeStringList(entry.value);
        if (vals.isNotEmpty) _multiSelectValues[entry.key] = vals.toSet();
        continue;
      }
      if (type == 'repeatable_text') {
        final vals = _decodeStringList(entry.value);
        if (vals.isNotEmpty) {
          _repeatableTextControllers[entry.key] =
              vals.map((e) => TextEditingController(text: e)).toList();
        }
        continue;
      }
      if (type == 'repeatable_group') {
        final list = _decodeListMap(entry.value);
        final itemFields = (def['itemFields'] as List<dynamic>?) ?? const [];
        if (list.isNotEmpty) {
          _repeatableGroupControllers[entry.key] =
              _buildGroupRowsFromData(list, itemFields);
        }
        continue;
      }
      final text = entry.value?.toString() ?? '';
      if (text.trim().isNotEmpty) {
        _draftGenericTexts[entry.key] = text;
      }
    }
    final latestFollow = (latest['followUpDate'] ?? '').toString().trim();
    if (latestFollow.isNotEmpty && _followUpDate.trim().isEmpty) {
      _followUpDate = latestFollow;
      _addFollowUp = true;
    }
  }

  Map<String, dynamic>? _findFieldDefinition(String fieldId) {
    final sections = (_form?['sections'] as List<dynamic>?) ?? const [];
    for (final sectionRaw in sections) {
      if (sectionRaw is! Map<String, dynamic>) continue;
      final fields = (sectionRaw['fields'] as List<dynamic>?) ?? const [];
      for (final fieldRaw in fields) {
        if (fieldRaw is! Map<String, dynamic>) continue;
        if ((fieldRaw['id'] ?? '').toString() == fieldId) {
          return fieldRaw;
        }
      }
    }
    return null;
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
        return decoded
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [text];
  }

  List<Map<String, dynamic>> _decodeListMap(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }
    final text = (raw ?? '').toString().trim();
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

  List<Map<String, dynamic>> _buildGroupRowsFromData(
    List<Map<String, dynamic>> data,
    List<dynamic> itemFields,
  ) {
    final rows = <Map<String, dynamic>>[];
    for (final source in data) {
      final row = <String, dynamic>{};
      for (final rawField in itemFields) {
        if (rawField is! Map<String, dynamic>) continue;
        final fid = (rawField['id'] ?? '').toString();
        if (fid.isEmpty) continue;
        final ftype = (rawField['type'] ?? 'text').toString();
        final rawVal = source[fid];
        if (ftype == 'select') {
          row[fid] = rawVal?.toString();
        } else if (ftype == 'repeatable_text') {
          final list = _decodeStringList(rawVal);
          row[fid] = list.isEmpty
              ? <TextEditingController>[TextEditingController()]
              : list.map((e) => TextEditingController(text: e)).toList();
        } else if (ftype == 'repeatable_group') {
          final nestedFields =
              (rawField['itemFields'] as List<dynamic>?) ?? const [];
          final nestedData = _decodeListMap(rawVal);
          row[fid] = nestedData.isEmpty
              ? <Map<String, dynamic>>[_initGroupRow(nestedFields)]
              : _buildGroupRowsFromData(nestedData, nestedFields);
        } else {
          row[fid] = TextEditingController(text: (rawVal ?? '').toString());
        }
      }
      rows.add(row);
    }
    return rows.isEmpty ? <Map<String, dynamic>>[_initGroupRow(itemFields)] : rows;
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

  bool _roleAllows(Map<String, dynamic> field) {
    final roles = field['roles'];
    if (roles is! List || roles.isEmpty) return true;
    final normalized = MedicalRolePolicy.normalize(_userRole);
    for (final raw in roles) {
      final role = raw.toString().trim().toLowerCase();
      if (role == normalized) return true;
      if (role == 'admin' && normalized == 'creator') return true;
      if (role == 'field' && normalized == 'collector') return true;
      if (role == 'doctor' && MedicalRolePolicy.canEditAssessmentPlan(_userRole)) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> _initGroupRow(List<dynamic> itemFields) {
    final row = <String, dynamic>{};
    for (final raw in itemFields) {
      if (raw is! Map<String, dynamic>) continue;
      final id = (raw['id'] ?? '').toString();
      final type = (raw['type'] ?? 'text').toString();
      if (id.isEmpty) continue;
      if (type == 'repeatable_text') {
        row[id] = <TextEditingController>[TextEditingController()];
      } else if (type == 'select') {
        row[id] = null;
      } else {
        row[id] = TextEditingController();
      }
    }
    return row;
  }

  List<Map<String, dynamic>> _rowsForGroup(
    String groupId,
    List<dynamic> itemFields,
  ) {
    final existing = _repeatableGroupControllers[groupId];
    if (existing != null && existing.isNotEmpty) return existing;
    final rows = <Map<String, dynamic>>[_initGroupRow(itemFields)];
    _repeatableGroupControllers[groupId] = rows;
    return rows;
  }

  Widget _buildRepeatableTextList({
    required String label,
    required List<TextEditingController> controllers,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => controllers.add(TextEditingController()));
                _saveDraft();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
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
                    onChanged: (_) => _saveDraft(),
                    decoration: InputDecoration(
                      labelText: '$label ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: controllers.length <= 1
                      ? null
                      : () {
                          setState(() {
                            final removed = controllers.removeAt(index);
                            removed.dispose();
                          });
                          _saveDraft();
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

  Widget _buildMultiSelectField(Map<String, dynamic> field) {
    final id = (field['id'] ?? '').toString();
    final label = (field['label'] ?? id).toString();
    final layout = (field['layout'] ?? '').toString().toLowerCase();
    final options = (field['options'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    final selected = _multiSelectValues[id] ?? <String>{};
    _multiSelectValues[id] = selected;
    final chips = options
        .map(
          (opt) => FilterChip(
            label: Text(opt),
            selected: selected.contains(opt),
            onSelected: (v) {
              setState(() {
                if (v) {
                  selected.add(opt);
                } else {
                  selected.remove(opt);
                }
              });
              _saveDraft();
            },
          ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (layout == 'horizontal')
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips
                  .map((chip) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: chip,
                      ))
                  .toList(),
            ),
          )
        else
          Wrap(
            spacing: 8,
            children: chips,
          ),
      ],
    );
  }

  Widget _buildRepeatableTextField(Map<String, dynamic> field) {
    final id = (field['id'] ?? '').toString();
    final label = (field['label'] ?? id).toString();
    final list = _repeatableTextControllers[id] ??=
        <TextEditingController>[TextEditingController()];
    return _buildRepeatableTextList(label: label, controllers: list);
  }

  Widget _buildRepeatableGroupField(Map<String, dynamic> field) {
    final id = (field['id'] ?? '').toString();
    final label = (field['label'] ?? id).toString();
    final itemFields = (field['itemFields'] as List<dynamic>?) ?? const [];
    final rows = _rowsForGroup(id, itemFields);

    Widget buildItemField(
      Map<String, dynamic> fieldMeta,
      Map<String, dynamic> row,
    ) {
      final fid = (fieldMeta['id'] ?? '').toString();
      final flabel = (fieldMeta['label'] ?? fid).toString();
      final ftype = (fieldMeta['type'] ?? 'text').toString();
      if (fid.isEmpty) return const SizedBox.shrink();
      if (ftype == 'repeatable_text') {
        final raw = row[fid];
        List<TextEditingController> list;
        if (raw is List<TextEditingController>) {
          list = raw;
        } else if (raw is List) {
          list = raw
              .map((e) => TextEditingController(text: e.toString()))
              .toList();
          row[fid] = list;
        } else {
          list = <TextEditingController>[TextEditingController()];
          row[fid] = list;
        }
        return _buildRepeatableTextList(label: flabel, controllers: list);
      }
      if (ftype == 'repeatable_group') {
        final nestedFields =
            (fieldMeta['itemFields'] as List<dynamic>?) ?? const [];
        final raw = row[fid];
        List<Map<String, dynamic>> nestedRows;
        if (raw is List<Map<String, dynamic>>) {
          nestedRows = raw;
        } else if (raw is List) {
          nestedRows = raw
              .whereType<Map>()
              .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
              .toList();
          if (nestedRows.isEmpty) {
            nestedRows = <Map<String, dynamic>>[_initGroupRow(nestedFields)];
          }
          row[fid] = nestedRows;
        } else {
          nestedRows = <Map<String, dynamic>>[_initGroupRow(nestedFields)];
          row[fid] = nestedRows;
        }
        return Card(
          color: Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        flabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => nestedRows.add(_initGroupRow(nestedFields)));
                        _saveDraft();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...nestedRows.asMap().entries.map((nestedEntry) {
                  final idx = nestedEntry.key;
                  final nestedRow = nestedEntry.value;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text('Item ${idx + 1}'),
                              const Spacer(),
                              IconButton(
                                onPressed: nestedRows.length <= 1
                                    ? null
                                    : () {
                                        setState(() {
                                          final removed = nestedRows.removeAt(idx);
                                          for (final val in removed.values) {
                                            if (val is TextEditingController) {
                                              val.dispose();
                                            } else if (val
                                                is List<TextEditingController>) {
                                              for (final c in val) {
                                                c.dispose();
                                              }
                                            }
                                          }
                                        });
                                        _saveDraft();
                                      },
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                            ],
                          ),
                          ...nestedFields.map((nestedField) {
                            if (nestedField is! Map<String, dynamic>) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: buildItemField(nestedField, nestedRow),
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
      if (ftype == 'select') {
        final options = (fieldMeta['options'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [];
        final raw = row[fid];
        if (raw is TextEditingController) {
          row[fid] = raw.text;
        }
        final current = row[fid] as String?;
        return DropdownButtonFormField<String>(
          initialValue: current,
          items:
              options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (v) {
            setState(() => row[fid] = v);
            _saveDraft();
          },
          decoration: InputDecoration(labelText: flabel),
        );
      }
      final existing = row[fid];
      if (existing is String) {
        row[fid] = TextEditingController(text: existing);
      }
      TextEditingController controller;
      final value = row[fid];
      if (value is TextEditingController) {
        controller = value;
      } else {
        controller = TextEditingController();
        row[fid] = controller;
      }
      return TextFormField(
        controller: controller,
        readOnly: ftype == 'date',
        onTap: ftype == 'date'
            ? () async {
                await _pickDate(controller);
                _saveDraft();
              }
            : null,
        onChanged: (_) => _saveDraft(),
        keyboardType: ftype == 'number' ? TextInputType.number : TextInputType.text,
        minLines: ftype == 'textarea' ? 3 : 1,
        maxLines: ftype == 'textarea' ? 6 : 1,
        decoration: InputDecoration(labelText: flabel),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => rows.add(_initGroupRow(itemFields)));
                _saveDraft();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Item ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        onPressed: rows.length <= 1
                            ? null
                            : () {
                                setState(() {
                                  final removed = rows.removeAt(index);
                                  for (final v in removed.values) {
                                    if (v is TextEditingController) {
                                      v.dispose();
                                    } else if (v is List<TextEditingController>) {
                                      for (final c in v) {
                                        c.dispose();
                                      }
                                    }
                                  }
                                });
                                _saveDraft();
                              },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...itemFields.map((f) {
                    if (f is! Map<String, dynamic>) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: buildItemField(f, row),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPreviousEntriesCard() {
    final raw = widget.contextData?['previousEntries'];
    if (raw is! List || raw.isEmpty) return const SizedBox.shrink();
    final entries = raw
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    final recent = entries.reversed.take(3).toList();

    List<Map<String, dynamic>> decodeList(dynamic value) {
      if (value is List) {
        return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      final text = value?.toString() ?? '';
      if (text.trim().isEmpty) return const [];
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) {
          return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      } catch (_) {}
      return const [];
    }

    List<String> decodeStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      final text = value?.toString() ?? '';
      if (text.trim().isEmpty) return const [];
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {}
      return const [];
    }

    return Card(
      color: Colors.blueGrey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Previous Entries (Read-only)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...recent.map((entry) {
              final values = entry['values'] is Map
                  ? (entry['values'] as Map).map(
                      (k, v) => MapEntry(k.toString(), v),
                    )
                  : <String, dynamic>{};
              final complaints = decodeList(values['chief_complaints']);
              final diseases = <String>{
                ...decodeStringList(values['ncd_tags']),
                ...decodeList(values['comorbid_ncd_list'])
                    .map((row) => (row['disease'] ?? '').toString().trim())
                    .where((d) => d.isNotEmpty),
              }.toList();
              final date = (entry['submittedAt'] ?? entry['followUpDate'] ?? '')
                  .toString()
                  .split('T')
                  .first;
              final complaintText = complaints.isEmpty
                  ? 'No complaints recorded'
                  : complaints
                      .map((c) =>
                          '${c['complaint'] ?? ''} (${c['duration'] ?? '-'})')
                      .where((e) => e.trim().isNotEmpty)
                      .join(', ');
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${date.isEmpty ? '-' : date}'),
                    Text('Complaints: $complaintText'),
                    if (diseases.isNotEmpty)
                      Text('NCD: ${diseases.join(', ')}'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSameDayFormsCard() {
    final raw = widget.contextData?['sameDayForms'];
    if (raw is! List || raw.isEmpty) return const SizedBox.shrink();
    final entries = raw
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    final snapshot = _buildSameDayClinicalSnapshot(entries);
    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Same Day Forms (Read-only)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (snapshot['treatments']!.isNotEmpty) ...[
              const Text(
                'Treatments',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ...snapshot['treatments']!.map((e) => Text('- $e')),
              const SizedBox(height: 8),
            ],
            if (snapshot['investigations']!.isNotEmpty) ...[
              const Text(
                'Investigations',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ...snapshot['investigations']!.map((e) => Text('- $e')),
              const SizedBox(height: 8),
            ],
            ...entries.take(8).map((entry) {
              final title = (entry['formTitle'] ?? entry['formId'] ?? '-').toString();
              final date = (entry['submittedAt'] ?? '').toString();
              final day = date.isEmpty ? '-' : date.split('T').first;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $title ($day)'),
              );
            }),
          ],
        ),
      ),
    );
  }

  Map<String, List<String>> _buildSameDayClinicalSnapshot(
    List<Map<String, dynamic>> entries,
  ) {
    final treatments = <String>{};
    final investigations = <String>{};
    for (final entry in entries) {
      final values = entry['values'];
      if (values is! Map) continue;
      final map = values.map((k, v) => MapEntry(k.toString(), v));
      final treatmentKeys = <String>[
        'treatment_plan',
        'overall_treatment_plan',
        'new_treatment',
        'current_meds',
        'currentMedications',
      ];
      final investigationKeys = <String>[
        'investigations_to_do',
        'overall_investigation_plan',
        'new_investigations',
        'investigations_advised',
      ];
      for (final k in treatmentKeys) {
        final val = map[k];
        final text = val?.toString().trim() ?? '';
        if (text.isEmpty) continue;
        if (text.startsWith('[') && text.endsWith(']')) {
          try {
            final parsed = jsonDecode(text);
            if (parsed is List) {
              for (final item in parsed) {
                final t = item.toString().trim();
                if (t.isNotEmpty) treatments.add(t);
              }
              continue;
            }
          } catch (_) {}
        }
        treatments.add(text);
      }
      for (final k in investigationKeys) {
        final val = map[k];
        final text = val?.toString().trim() ?? '';
        if (text.isEmpty) continue;
        if (text.startsWith('[') && text.endsWith(']')) {
          try {
            final parsed = jsonDecode(text);
            if (parsed is List) {
              for (final item in parsed) {
                final t = item.toString().trim();
                if (t.isNotEmpty) investigations.add(t);
              }
              continue;
            }
          } catch (_) {}
        }
        investigations.add(text);
      }
    }
    return {
      'treatments': treatments.toList(),
      'investigations': investigations.toList(),
    };
  }

  String _calculateClinicalNcdDurationSummary({
    required String diseaseRowsRaw,
    required String projectedFollowDateRaw,
  }) {
    final rows = _decodeListMap(diseaseRowsRaw);
    if (rows.isEmpty) return '';
    final previousRaw = widget.contextData?['previousEntries'];
    DateTime? firstEntryDate;
    if (previousRaw is List && previousRaw.isNotEmpty) {
      final first = previousRaw.first;
      if (first is Map) {
        final firstMap = first.map((k, v) => MapEntry(k.toString(), v));
        final firstDateRaw =
            (firstMap['submittedAt'] ?? firstMap['followUpDate'] ?? '').toString();
        firstEntryDate = DateTime.tryParse(firstDateRaw);
      }
    }
    final today = DateTime.now();
    final dayToday = DateTime(today.year, today.month, today.day);
    final start = firstEntryDate == null
        ? dayToday
        : DateTime(firstEntryDate.year, firstEntryDate.month, firstEntryDate.day);
    final projected = DateTime.tryParse(projectedFollowDateRaw);
    final dayProjected = projected == null
        ? dayToday
        : DateTime(projected.year, projected.month, projected.day);
    final elapsedDays = dayToday.difference(start).inDays.clamp(0, 100000);
    final projectedDiff = dayProjected.difference(dayToday).inDays.clamp(0, 100000);

    int baselineToDays(String baseline) {
      final text = baseline.toLowerCase().trim();
      final number = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (number <= 0) return 0;
      if (text.contains('year')) return number * 365;
      if (text.contains('month')) return number * 30;
      if (text.contains('week')) return number * 7;
      return number;
    }

    final lines = <String>[];
    for (final row in rows) {
      final disease = (row['disease'] ?? '').toString().trim();
      if (disease.isEmpty) continue;
      final baseline = (row['duration'] ?? '').toString().trim();
      final baselineDays = baselineToDays(baseline);
      final totalProjectedDays = baselineDays + elapsedDays + projectedDiff;
      lines.add(
        '$disease | baseline: ${baseline.isEmpty ? "-" : baseline} | '
        'elapsed: ${elapsedDays}d | projected till follow-up: ${totalProjectedDays}d',
      );
    }
    return lines.join('\n');
  }

  Widget _buildClinicalNcdDevices() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connected Devices (Optional)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _deviceCard(
              device: DeviceType.ecg,
              title: 'ECG',
              liveText: _ecgLive,
              onCapture: () => _captureReading(DeviceType.ecg),
            ),
            _deviceCard(
              device: DeviceType.pft,
              title: 'PFT',
              liveText: _pftLive,
              onCapture: () => _captureReading(DeviceType.pft),
            ),
            _deviceCard(
              device: DeviceType.steth,
              title: 'Digital Steth',
              liveText: _stethLive,
              onCapture: () => _captureReading(DeviceType.steth),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSectionVisible(Map<String, dynamic> section) {
    if (!_isClinicalNcd) return true;
    final id = (section['id'] ?? '').toString().trim().toLowerCase();
    if (!id.startsWith('complication_')) return true;
    final selected = _selectedClinicalNcdTags();
    if (selected.isEmpty) return false;
    final sectionToTags = <String, Set<String>>{
      'complication_dm': {'Diabetes'},
      'complication_htn': {'Hypertension'},
      'complication_oral_cancer': {'Oral Cancer'},
      'complication_breast_cancer': {'Breast Cancer'},
      'complication_cervical_cancer': {'Cervical Cancer'},
      'complication_respiratory': {'COPD', 'Asthma'},
      'complication_renal_cardiac_neuro': {'CKD', 'IHD', 'Stroke'},
      'complication_other': {'Other'},
    };
    final required = sectionToTags[id];
    if (required == null || required.isEmpty) return true;
    return selected.any(required.contains);
  }

  List<Map<String, dynamic>> _visibleSections() {
    final sections = (_form?['sections'] as List<dynamic>?) ?? const [];
    final visible = <Map<String, dynamic>>[];
    for (final raw in sections) {
      if (raw is! Map<String, dynamic>) continue;
      if (!_isSectionVisible(raw)) continue;
      visible.add(raw);
    }
    return visible;
  }

  bool _isFieldFilled(Map<String, dynamic> field) {
    if (!_roleAllows(field)) return true;
    final id = (field['id'] ?? '').toString();
    final type = (field['type'] ?? 'text').toString();
    if (id.isEmpty) return true;
    if (type == 'select') {
      return (_selectValues[id] ?? '').trim().isNotEmpty;
    }
    if (type == 'multiselect') {
      return (_multiSelectValues[id] ?? <String>{}).isNotEmpty;
    }
    if (type == 'repeatable_text') {
      final rows = _repeatableTextControllers[id] ?? const <TextEditingController>[];
      return rows.any((c) => c.text.trim().isNotEmpty);
    }
    if (type == 'repeatable_group') {
      final rows = _repeatableGroupControllers[id] ?? const <Map<String, dynamic>>[];
      for (final row in rows) {
        for (final value in row.values) {
          if (value is TextEditingController && value.text.trim().isNotEmpty) {
            return true;
          }
          if (value is String && value.trim().isNotEmpty) return true;
          if (value is List<TextEditingController>) {
            if (value.any((c) => c.text.trim().isNotEmpty)) return true;
          }
          if (value is List<Map<String, dynamic>>) {
            for (final nested in value) {
              for (final nestedValue in nested.values) {
                if (nestedValue is TextEditingController &&
                    nestedValue.text.trim().isNotEmpty) {
                  return true;
                }
                if (nestedValue is String && nestedValue.trim().isNotEmpty) {
                  return true;
                }
              }
            }
          }
        }
      }
      return false;
    }
    return (_controllers[id]?.text ?? '').trim().isNotEmpty;
  }

  bool _isSectionCompleted(Map<String, dynamic> section) {
    final fields = (section['fields'] as List<dynamic>?) ?? const [];
    final visibleFields = fields
        .whereType<Map<String, dynamic>>()
        .where(_roleAllows)
        .toList();
    if (visibleFields.isEmpty) return true;
    return visibleFields.any(_isFieldFilled);
  }

  List<String> _missingRequiredFieldLabels(Map<String, dynamic> section) {
    final fields = (section['fields'] as List<dynamic>?) ?? const [];
    final missing = <String>[];
    for (final raw in fields) {
      if (raw is! Map<String, dynamic>) continue;
      if (!_roleAllows(raw)) continue;
      if (raw['required'] != true) continue;
      if (_isFieldFilled(raw)) continue;
      final id = (raw['id'] ?? '').toString();
      final label = (raw['label'] ?? id).toString();
      if (label.isNotEmpty) missing.add(label);
    }
    return missing;
  }

  Future<void> _nextSection() async {
    final sections = _visibleSections();
    if (sections.isEmpty) return;
    final current = sections[_activeSectionIndex.clamp(0, sections.length - 1)];
    final missing = _missingRequiredFieldLabels(current);
    if (missing.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fill required fields: ${missing.take(3).join(', ')}'),
        ),
      );
      return;
    }
    if (_activeSectionIndex >= sections.length - 1) return;
    setState(() => _activeSectionIndex += 1);
  }

  void _jumpToFirstIncomplete() {
    final sections = _visibleSections();
    if (sections.isEmpty) return;
    for (var i = 0; i < sections.length; i++) {
      if (!_isSectionCompleted(sections[i])) {
        setState(() => _activeSectionIndex = i);
        return;
      }
    }
  }

  Set<String> _selectedClinicalNcdTags() {
    final selected = <String>{};
    selected.addAll(_multiSelectValues['ncd_tags'] ?? <String>{});
    final rows = _repeatableGroupControllers['disease_wise_details'] ?? const [];
    for (final row in rows) {
      final raw = row['disease'];
      String disease = '';
      if (raw is String) {
        disease = raw.trim();
      } else if (raw is TextEditingController) {
        disease = raw.text.trim();
      }
      if (disease.isNotEmpty) {
        selected.add(disease);
      }
    }
    final listRows = _repeatableGroupControllers['comorbid_ncd_list'] ?? const [];
    for (final row in listRows) {
      final raw = row['disease'];
      String disease = '';
      if (raw is String) {
        disease = raw.trim();
      } else if (raw is TextEditingController) {
        disease = raw.text.trim();
      }
      if (disease.isNotEmpty) {
        selected.add(disease);
      }
    }
    return selected;
  }

  Widget _buildGenericField(Map<String, dynamic> field) {
    final id = (field['id'] ?? '').toString();
    final label = (field['label'] ?? id).toString();
    final required = field['required'] == true;
    final decoratedLabel = required ? '$label *' : label;
    final type = (field['type'] ?? 'text').toString();
    final options = (field['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];
    if (!_roleAllows(field)) {
      return const SizedBox.shrink();
    }

    if (type == 'multiselect') {
      return _buildMultiSelectField(field);
    }
    if (type == 'repeatable_text') {
      return _buildRepeatableTextField(field);
    }
    if (type == 'repeatable_group') {
      return _buildRepeatableGroupField(field);
    }
    if (type == 'select') {
      return DropdownButtonFormField<String>(
        initialValue: _selectValues[id],
        items: options
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) {
          setState(() => _selectValues[id] = v);
          _saveDraft();
        },
        decoration: InputDecoration(labelText: decoratedLabel),
      );
    }
    final c = _controllers[id] ??=
        TextEditingController(text: _draftGenericTexts[id] ?? '');
    final isTextArea = type == 'textarea';
    return TextFormField(
      controller: c,
      readOnly: type == 'date',
      onTap: type == 'date'
          ? () async {
              await _pickDate(c);
              _saveDraft();
            }
          : null,
      onChanged: (_) => _saveDraft(),
      keyboardType: type == 'number' ? TextInputType.number : TextInputType.text,
      minLines: isTextArea ? 3 : 1,
      maxLines: isTextArea ? 6 : 1,
      decoration: InputDecoration(labelText: decoratedLabel),
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
    final resolvedFollow = _addFollowUp
        ? _followUpDate.trim().isNotEmpty
            ? _followUpDate.trim()
            : DateTime.now()
                .add(const Duration(days: 30))
                .toIso8601String()
                .split('T')
                .first
        : '';
    return {
      'formId': 'anc',
      'formTitle': (_form?['title'] ?? 'ANC').toString(),
      'followUpSkipped': !_addFollowUp,
      'followUpDate': resolvedFollow,
      'submittedAt': DateTime.now().toIso8601String(),
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
      _clearDraft();
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
    for (final e in _multiSelectValues.entries) {
      values[e.key] = jsonEncode(e.value.toList());
    }
    for (final e in _repeatableTextControllers.entries) {
      final list = e.value.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
      values[e.key] = jsonEncode(list);
    }
    for (final e in _repeatableGroupControllers.entries) {
      final rows = <Map<String, dynamic>>[];
      for (final row in e.value) {
        final mapped = <String, dynamic>{};
        row.forEach((key, val) {
          if (val is TextEditingController) {
            mapped[key] = val.text.trim();
          } else if (val is List<TextEditingController>) {
            mapped[key] = val
                .map((c) => c.text.trim())
                .where((t) => t.isNotEmpty)
                .toList();
          } else {
            mapped[key] = val;
          }
        });
        rows.add(mapped);
      }
      values[e.key] = jsonEncode(rows);
    }
    if (_isClinicalNcd) {
      final sameDayRaw = widget.contextData?['sameDayForms'];
      if (sameDayRaw is List) {
        final entries = sameDayRaw
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
        final snapshot = _buildSameDayClinicalSnapshot(entries);
        values['same_day_treatments_readonly'] = jsonEncode(snapshot['treatments']);
        values['same_day_investigations_readonly'] =
            jsonEncode(snapshot['investigations']);
      }
      final projectedFollow = (values['follow_up_date'] ?? values['next_followup_date'] ?? '')
          .toString()
          .trim();
      final summary = _calculateClinicalNcdDurationSummary(
        diseaseRowsRaw: values['disease_wise_details'] ?? '',
        projectedFollowDateRaw: projectedFollow,
      );
      if (summary.isNotEmpty) {
        values['calculated_duration_summary'] = summary;
      }
    }
    final explicitFromValues =
        (values['next_visit_date'] ?? values['follow_up_date'] ?? '').trim();
    if (_isClinicalNcd && explicitFromValues.isEmpty) {
      final proposed = (values['proposed_follow_up_date'] ?? '').trim();
      if (proposed.isNotEmpty) {
        values['follow_up_date'] = proposed;
      }
    }
    final explicitFollow =
        (values['next_visit_date'] ?? values['follow_up_date'] ?? '').trim();
    final shouldUseFollow = _addFollowUp || explicitFollow.isNotEmpty;
    final resolvedFollow = shouldUseFollow
        ? explicitFollow.isNotEmpty
            ? explicitFollow
            : _followUpDate.isNotEmpty
                ? _followUpDate
                : (_followUpEnabled && (_followUpCycleDays ?? 0) > 0)
                    ? DateTime.now()
                        .add(Duration(days: _followUpCycleDays!))
                        .toIso8601String()
                        .split('T')
                        .first
                    : ''
        : '';
    final followUpSkipped = !_addFollowUp && explicitFollow.isEmpty;
    Navigator.pop(context, {
      'formId': (_form?['id'] ?? '').toString(),
      'formTitle': (_form?['title'] ?? 'Form').toString(),
      'values': values,
      'followUpSkipped': followUpSkipped,
      'followUpDate': resolvedFollow,
      'submittedAt': DateTime.now().toIso8601String(),
    });
    _clearDraft();
  }

  Widget _buildCommonFollowUpDateField() {
    return TextFormField(
      readOnly: true,
      onTap: () async {
        final temp = TextEditingController(text: _followUpDate);
        await _pickDate(temp);
        setState(() => _followUpDate = temp.text.trim());
        await _saveDraft();
        temp.dispose();
      },
      decoration: InputDecoration(
        labelText: 'Follow-up Date',
        hintText: _followUpDate.isEmpty ? 'Select date' : _followUpDate,
        suffixIcon: const Icon(Icons.calendar_today),
      ),
    );
  }

  Widget _buildFollowUpAddonSection() {
    final subtitle = (_followUpCycleDays ?? 0) > 0
        ? 'Suggested every ${_followUpCycleDays} days'
        : 'Optional';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Add Follow-up'),
              subtitle: Text(subtitle),
              value: _addFollowUp,
              onChanged: (v) async {
                setState(() {
                  _addFollowUp = v;
                  if (!_addFollowUp) {
                    _followUpDate = '';
                  }
                  if (_addFollowUp &&
                      _followUpDate.trim().isEmpty &&
                      (_followUpCycleDays ?? 0) > 0) {
                    _followUpDate = DateTime.now()
                        .add(Duration(days: _followUpCycleDays!))
                        .toIso8601String()
                        .split('T')
                        .first;
                  }
                });
                await _saveDraft();
              },
            ),
            if (_addFollowUp) ...[
              const SizedBox(height: 8),
              _buildCommonFollowUpDateField(),
            ],
          ],
        ),
      ),
    );
  }

  String _draftKey() {
    final formId = (_form?['id'] ?? widget.assetPath).toString();
    final entity = (widget.entityLabel ?? 'na').replaceAll(' ', '_');
    return 'draft_${formId}_$entity';
  }

  Map<String, dynamic> _captureDraftPayload() {
    final payload = <String, dynamic>{
      'followUpDate': _followUpDate,
      'addFollowUp': _addFollowUp,
      'genericTexts': _controllers.map((k, v) => MapEntry(k, v.text)),
      'genericSelects': _selectValues,
      'repeatableText': _repeatableTextControllers.map(
        (k, v) => MapEntry(k, v.map((c) => c.text).toList()),
      ),
      'repeatableGroups': _repeatableGroupControllers.map((k, rows) {
        final mappedRows = rows.map((row) {
          final mapped = <String, dynamic>{};
          row.forEach((key, val) {
            if (val is TextEditingController) {
              mapped[key] = val.text;
            } else if (val is List<TextEditingController>) {
              mapped[key] = val.map((c) => c.text).toList();
            } else {
              mapped[key] = val;
            }
          });
          return mapped;
        }).toList();
        return MapEntry(k, mappedRows);
      }),
      'multiSelects':
          _multiSelectValues.map((k, v) => MapEntry(k, v.toList())),
    };
    if (_isAnc) {
      payload['anc'] = {
        'visitType': _ancVisitType,
        'picme': _picme.text,
        'lmp': _lmp.text,
        'edd': _edd.text,
        'gaWeeks': _gaWeeks.text,
        'trimester': _trimester.text,
        'totalAncVisits': _totalAncVisits.text,
        'gpla': _gpla.text,
        'height': _height.text,
        'weight': _weight.text,
        'weightGain': _weightGain.text,
        'complaints': _complaints.map((e) => e.text).toList(),
        'coMorbid': _coMorbid.map((e) => e.text).toList(),
      };
    }
    return payload;
  }

  Future<void> _saveDraft() async {
    if (_form == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_draftKey(), jsonEncode(_captureDraftPayload()));
    } catch (_) {}
  }

  Future<void> _loadDraft() async {
    if (_form == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey()) ?? '';
      if (raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      _followUpDate = (decoded['followUpDate'] ?? '').toString();
      final hasAddFollowUpFlag = decoded.containsKey('addFollowUp');
      _addFollowUp = decoded['addFollowUp'] == true;
      if (!hasAddFollowUpFlag && _followUpDate.trim().isNotEmpty) {
        _addFollowUp = true;
      }

      final genericTexts = decoded['genericTexts'];
      if (genericTexts is Map<String, dynamic>) {
        _draftGenericTexts.addAll(
          genericTexts.map((k, v) => MapEntry(k, (v ?? '').toString())),
        );
      }
      final genericSelects = decoded['genericSelects'];
      if (genericSelects is Map<String, dynamic>) {
        _draftGenericSelects.addAll(
          genericSelects.map((k, v) => MapEntry(k, v?.toString())),
        );
        _selectValues.addAll(_draftGenericSelects);
      }

      final repeatableText = decoded['repeatableText'];
      if (repeatableText is Map<String, dynamic>) {
        repeatableText.forEach((key, value) {
          final list = (value as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList();
          _repeatableTextControllers[key] =
              list.isEmpty ? [TextEditingController()] : list.map((e) => TextEditingController(text: e)).toList();
        });
      }

      final repeatableGroups = decoded['repeatableGroups'];
      if (repeatableGroups is Map<String, dynamic>) {
        repeatableGroups.forEach((key, value) {
          final rows = <Map<String, dynamic>>[];
          final list = value as List<dynamic>? ?? const [];
          for (final rawRow in list) {
            if (rawRow is! Map<String, dynamic>) continue;
            final row = <String, dynamic>{};
            rawRow.forEach((fieldId, fieldValue) {
              if (fieldValue is List) {
                row[fieldId] = fieldValue
                    .map((e) => TextEditingController(text: e?.toString() ?? ''))
                    .toList();
              } else {
                row[fieldId] = TextEditingController(
                  text: fieldValue?.toString() ?? '',
                );
              }
            });
            rows.add(row);
          }
          if (rows.isNotEmpty) {
            _repeatableGroupControllers[key] = rows;
          }
        });
      }

      final multiSelects = decoded['multiSelects'];
      if (multiSelects is Map<String, dynamic>) {
        multiSelects.forEach((key, value) {
          final list = (value as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toSet();
          _multiSelectValues[key] = list;
        });
      }

      if (_isAnc) {
        final anc = decoded['anc'];
        if (anc is Map<String, dynamic>) {
          _ancVisitType = (anc['visitType'] ?? _ancVisitType).toString();
          _picme.text = (anc['picme'] ?? '').toString();
          _lmp.text = (anc['lmp'] ?? '').toString();
          _edd.text = (anc['edd'] ?? '').toString();
          _gaWeeks.text = (anc['gaWeeks'] ?? '').toString();
          _trimester.text = (anc['trimester'] ?? '').toString();
          _totalAncVisits.text = (anc['totalAncVisits'] ?? '').toString();
          _gpla.text = (anc['gpla'] ?? '').toString();
          _height.text = (anc['height'] ?? '').toString();
          _weight.text = (anc['weight'] ?? '').toString();
          _weightGain.text = (anc['weightGain'] ?? '').toString();

          final complaints = (anc['complaints'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList();
          if (complaints.isNotEmpty) {
            for (final c in _complaints) {
              c.dispose();
            }
            _complaints
              ..clear()
              ..addAll(complaints.map((e) => TextEditingController(text: e)));
          }

          final coMorbid = (anc['coMorbid'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList();
          if (coMorbid.isNotEmpty) {
            for (final c in _coMorbid) {
              c.dispose();
            }
            _coMorbid
              ..clear()
              ..addAll(coMorbid.map((e) => TextEditingController(text: e)));
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey());
    } catch (_) {}
  }

  void _startDraftAutoSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _saveDraft();
    });
  }

  TextEditingController _controllerFor(String id) {
    return _controllers.putIfAbsent(
      id,
      () => TextEditingController(text: _draftGenericTexts[id] ?? ''),
    );
  }

  Future<void> _connectDevice(DeviceType device) async {
    await _deviceService.connect(device);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _disconnectDevice(DeviceType device) async {
    await _deviceService.disconnect(device);
    if (!mounted) return;
    setState(() {});
  }

  void _captureReading(DeviceType device) {
    if (device == DeviceType.ecg && _ecgLive.trim().isNotEmpty) {
      _selectValues['ecg_done'] = 'Yes';
      _controllerFor('ecg_summary').text = _ecgLive;
    }
    if (device == DeviceType.pft && _pftLive.trim().isNotEmpty) {
      _selectValues['pft_done'] = 'Yes';
      _controllerFor('pft_summary').text = _pftLive;
    }
    if (device == DeviceType.steth && _stethLive.trim().isNotEmpty) {
      _selectValues['digital_steth_done'] = 'Yes';
      _controllerFor('audio_summary').text = _stethLive;
    }
    _saveDraft();
    setState(() {});
  }

  Widget _deviceCard({
    required DeviceType device,
    required String title,
    required String liveText,
    required VoidCallback onCapture,
  }) {
    final connected = _deviceService.isConnected(device);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                Text(
                  connected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: connected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(liveText.isEmpty ? 'No live reading yet.' : liveText),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: connected ? null : () => _connectDevice(device),
                  icon: const Icon(Icons.usb),
                  label: const Text('Connect'),
                ),
                OutlinedButton.icon(
                  onPressed: connected ? () => _disconnectDevice(device) : null,
                  icon: const Icon(Icons.link_off),
                  label: const Text('Disconnect'),
                ),
                ElevatedButton.icon(
                  onPressed: connected ? onCapture : null,
                  icon: const Icon(Icons.download),
                  label: const Text('Capture'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMachineConnectForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.blue.shade50,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Device integration runs with native bridge if available, else mock stream. '
              'Use Connect and Capture to autofill fields.',
            ),
          ),
        ),
        const SizedBox(height: 8),
        _deviceCard(
          device: DeviceType.ecg,
          title: 'ECG',
          liveText: _ecgLive,
          onCapture: () => _captureReading(DeviceType.ecg),
        ),
        _deviceCard(
          device: DeviceType.pft,
          title: 'PFT',
          liveText: _pftLive,
          onCapture: () => _captureReading(DeviceType.pft),
        ),
        _deviceCard(
          device: DeviceType.steth,
          title: 'Digital Steth',
          liveText: _stethLive,
          onCapture: () => _captureReading(DeviceType.steth),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectValues['ecg_done'],
          items: const [
            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
            DropdownMenuItem(value: 'No', child: Text('No')),
          ],
          onChanged: (v) {
            setState(() => _selectValues['ecg_done'] = v);
            _saveDraft();
          },
          decoration: const InputDecoration(labelText: 'ECG Done'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controllerFor('ecg_summary'),
          onChanged: (_) => _saveDraft(),
          decoration: const InputDecoration(labelText: 'ECG Summary'),
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectValues['pft_done'],
          items: const [
            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
            DropdownMenuItem(value: 'No', child: Text('No')),
          ],
          onChanged: (v) {
            setState(() => _selectValues['pft_done'] = v);
            _saveDraft();
          },
          decoration: const InputDecoration(labelText: 'PFT Done'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controllerFor('pft_summary'),
          onChanged: (_) => _saveDraft(),
          decoration: const InputDecoration(labelText: 'PFT Summary'),
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectValues['digital_steth_done'],
          items: const [
            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
            DropdownMenuItem(value: 'No', child: Text('No')),
          ],
          onChanged: (v) {
            setState(() => _selectValues['digital_steth_done'] = v);
            _saveDraft();
          },
          decoration: const InputDecoration(labelText: 'Digital Steth Audio Captured'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controllerFor('audio_summary'),
          onChanged: (_) => _saveDraft(),
          decoration: const InputDecoration(labelText: 'Stethoscope Audio Summary'),
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controllerFor('machine_notes'),
          onChanged: (_) => _saveDraft(),
          decoration: const InputDecoration(labelText: 'Additional Notes'),
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('Save Machine Exam'),
        ),
      ],
    );
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
        _buildFollowUpAddonSection(),
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
          : _isMachineConnect
              ? _buildMachineConnectForm()
              : Builder(
                  builder: (context) {
                    final visibleSections = _visibleSections();
                    if (_activeSectionIndex >= visibleSections.length &&
                        visibleSections.isNotEmpty) {
                      _activeSectionIndex = visibleSections.length - 1;
                    }
                    final safeIndex = _activeSectionIndex.clamp(
                      0,
                      visibleSections.isEmpty ? 0 : visibleSections.length - 1,
                    );
                    final currentSection = visibleSections.isEmpty
                        ? null
                        : visibleSections[safeIndex];
                    final progress = visibleSections.isEmpty
                        ? 0.0
                        : (safeIndex + 1) / visibleSections.length;
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_isClinicalNcd) ...[
                          Card(
                            color: Colors.blue.shade50,
                            child: ListTile(
                              title: Text(_isDoctor ? 'Doctor View' : 'Field View'),
                              subtitle: Text(
                                _isDoctor
                                    ? 'Doctor sections are enabled. Confirm follow-up date.'
                                    : 'Field sections are enabled. Propose follow-up date for doctor confirmation.',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildPreviousEntriesCard(),
                          const SizedBox(height: 8),
                          _buildSameDayFormsCard(),
                          const SizedBox(height: 8),
                          _buildClinicalNcdDevices(),
                          const SizedBox(height: 8),
                        ],
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Section ${visibleSections.isEmpty ? 0 : safeIndex + 1}/${visibleSections.length}',
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(value: progress),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (var i = 0; i < visibleSections.length; i++)
                                      ChoiceChip(
                                        label: Text('${i + 1}'),
                                        selected: i == safeIndex,
                                        avatar: Icon(
                                          _isSectionCompleted(visibleSections[i])
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          size: 16,
                                        ),
                                        onSelected: (_) {
                                          setState(() => _activeSectionIndex = i);
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: _jumpToFirstIncomplete,
                                    icon: const Icon(Icons.flag_outlined),
                                    label: const Text('Jump to first incomplete'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isClinicalNcd && _selectedClinicalNcdTags().isEmpty)
                          Card(
                            color: Colors.orange.shade50,
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Add one or more NCD diseases in comorbidity section to show disease-specific complication sections.',
                              ),
                            ),
                          ),
                        if (_isClinicalNcd && _selectedClinicalNcdTags().isEmpty)
                          const SizedBox(height: 8),
                        if (currentSection != null)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (currentSection['title'] ?? currentSection['id'] ?? '').toString(),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  ...((currentSection['fields'] as List<dynamic>?) ?? const [])
                                      .map((f) {
                                    if (f is! Map<String, dynamic>) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _buildGenericField(f),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (!_isClinicalNcd) ...[
                          _buildFollowUpAddonSection(),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            if (visibleSections.isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: safeIndex > 0
                                    ? () => setState(() => _activeSectionIndex = safeIndex - 1)
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                                label: const Text('Previous'),
                              ),
                            const Spacer(),
                            if (visibleSections.isNotEmpty && safeIndex < visibleSections.length - 1)
                              ElevatedButton.icon(
                                onPressed: _nextSection,
                                icon: const Icon(Icons.chevron_right),
                                label: const Text('Next Section'),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: _save,
                                icon: const Icon(Icons.save),
                                label: const Text('Save Form'),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
