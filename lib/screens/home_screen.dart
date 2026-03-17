import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/area_code_service.dart';
import '../services/auth_service.dart';
import '../services/medical_role_policy.dart';
import 'admin_screen.dart';
import 'code_master_management_screen.dart';
import 'code_guide_screen.dart';
import 'data_collection_screen.dart';
import 'doctor_dashboard_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final AreaCodeService _areaCodeService = AreaCodeService();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _talukController = TextEditingController();
  final TextEditingController _phcController = TextEditingController();
  final TextEditingController _subcentreController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _clusterController = TextEditingController();
  final TextEditingController _cityVillageController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _workPlaceNameController = TextEditingController();
  final TextEditingController _anganwadiNameController = TextEditingController();
  final TextEditingController _stateCodeController = TextEditingController();
  final TextEditingController _districtCodeController = TextEditingController();
  final TextEditingController _talukCodeController = TextEditingController();
  final TextEditingController _localityCodeController = TextEditingController();
  final TextEditingController _areaSuffixCodeController = TextEditingController();
  final TextEditingController _dateOfEntryController = TextEditingController();

  String? _role;
  String? _name;
  String? _organizationName;
  bool _isLoggedIn = false;
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedSamplingUnit;
  String? _selectedIndividualEntryPoint;
  String _activeSamplingUnit = 'Family';
  List<AreaCodeEntry> _areaCodeEntries = [];
  bool _isSyncingAreaCode = false;
  List<Map<String, String>> _grids = [];
  bool _isDemoSession = false;

  static const List<String> _samplingUnits = [
    'Family',
    'Individual',
    'Community',
  ];
  static const List<String> _individualEntryPoints = [
    'PHC',
    'UPHC',
    'Anganwadi',
    'School',
    'Workplace',
    'Special Camp',
  ];

  @override
  void initState() {
    super.initState();
    _initializeHome();
  }

  Future<void> _initializeHome() async {
    try {
      final role = await _authService.getUserRole();
      await _loadSetupPreferences();
      _areaCodeEntries = await _areaCodeService.getEntries();
      if (!mounted) return;

      setState(() {
        final session = _authService.currentSession;
        _isDemoSession = (session?.organizationId == 'demo-org') ||
            ((session?.userId ?? '').toUpperCase().startsWith('DEMO-'));
        _role = role;
        _name = _authService.currentUserName;
        _organizationName = _authService.currentOrganizationName;
        _isLoggedIn = session != null;
        _selectedSamplingUnit ??= _samplingUnits.first;
        _selectedIndividualEntryPoint ??= _individualEntryPoints.first;
        _activeSamplingUnit = _selectedSamplingUnit ?? _samplingUnits.first;
        _initializeSetupDefaults();
        _ensureDemoSampleGrid();
        _errorMessage = null;
        _isLoading = false;
      });
      if (_authService.currentSession == null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load home data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAreaCodeEntries() async {
    _areaCodeEntries = await _areaCodeService.getEntries();
  }

  @override
  void dispose() {
    _stateController.dispose();
    _districtController.dispose();
    _talukController.dispose();
    _phcController.dispose();
    _subcentreController.dispose();
    _villageController.dispose();
    _clusterController.dispose();
    _cityVillageController.dispose();
    _schoolNameController.dispose();
    _workPlaceNameController.dispose();
    _anganwadiNameController.dispose();
    _stateCodeController.dispose();
    _districtCodeController.dispose();
    _talukCodeController.dispose();
    _localityCodeController.dispose();
    _areaSuffixCodeController.dispose();
    _dateOfEntryController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfEntry() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(_dateOfEntryController.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateOfEntryController.text = picked.toIso8601String().split('T').first;
    });
  }

  void _initializeSetupDefaults() {
    if (_dateOfEntryController.text.isEmpty) {
      _dateOfEntryController.text = DateTime.now().toIso8601String().split('T').first;
    }
  }

  Future<void> _loadSetupPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSampling = prefs.getString('setup_sampling_unit') ?? '';
    if (savedSampling == 'Person') {
      _selectedSamplingUnit = 'Individual';
      _selectedIndividualEntryPoint = 'PHC';
    } else if (savedSampling == 'Anganwadi' ||
        savedSampling == 'School' ||
        savedSampling == 'Work Place' ||
        savedSampling == 'PHC Area') {
      _selectedSamplingUnit = 'Individual';
      if (savedSampling == 'Anganwadi') _selectedIndividualEntryPoint = 'Anganwadi';
      if (savedSampling == 'School') _selectedIndividualEntryPoint = 'School';
      if (savedSampling == 'Work Place') _selectedIndividualEntryPoint = 'Workplace';
      if (savedSampling == 'PHC Area') _selectedIndividualEntryPoint = 'PHC';
    } else {
      _selectedSamplingUnit =
          savedSampling.isEmpty ? _selectedSamplingUnit : savedSampling;
    }
    final savedPoint = prefs.getString('setup_individual_entry_point') ?? '';
    if (savedPoint.isNotEmpty) {
      _selectedIndividualEntryPoint = savedPoint;
    }
    _activeSamplingUnit = _selectedSamplingUnit ?? _samplingUnits.first;
    _stateController.text = prefs.getString('setup_state') ?? '';
    _districtController.text = prefs.getString('setup_district') ?? '';
    _talukController.text = prefs.getString('setup_taluk') ?? '';
    _phcController.text = prefs.getString('setup_phc') ?? '';
    _subcentreController.text = prefs.getString('setup_subcentre') ?? '';
    _villageController.text = prefs.getString('setup_village') ?? '';
    _clusterController.text = prefs.getString('setup_cluster') ?? '';
    _cityVillageController.text = prefs.getString('setup_city_village') ?? '';
    _schoolNameController.text = prefs.getString('setup_school_name') ?? '';
    _workPlaceNameController.text = prefs.getString('setup_workplace_name') ?? '';
    _anganwadiNameController.text = prefs.getString('setup_anganwadi_name') ?? '';
    _stateCodeController.text = prefs.getString('setup_state_code') ?? '';
    _districtCodeController.text = prefs.getString('setup_district_code') ?? '';
    _talukCodeController.text = prefs.getString('setup_taluk_code') ?? '';
    _localityCodeController.text = prefs.getString('setup_locality_code') ?? '';
    _areaSuffixCodeController.text = prefs.getString('setup_area_suffix_code') ??
        prefs.getString('setup_cluster_code') ??
        '';
    _dateOfEntryController.text = prefs.getString('setup_date_of_entry') ?? '';
    _grids = _decodeGrids(prefs.getString('setup_grids'));
  }

  Future<void> _saveSetupPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('setup_sampling_unit', _selectedSamplingUnit ?? '');
    await prefs.setString(
      'setup_individual_entry_point',
      _selectedIndividualEntryPoint ?? '',
    );
    await prefs.setString('setup_state', _stateController.text.trim());
    await prefs.setString('setup_district', _districtController.text.trim());
    await prefs.setString('setup_taluk', _talukController.text.trim());
    await prefs.setString('setup_phc', _phcController.text.trim());
    await prefs.setString('setup_subcentre', _subcentreController.text.trim());
    await prefs.setString('setup_village', _villageController.text.trim());
    await prefs.setString('setup_cluster', _clusterController.text.trim());
    await prefs.setString('setup_city_village', _cityVillageController.text.trim());
    await prefs.setString('setup_school_name', _schoolNameController.text.trim());
    await prefs.setString('setup_workplace_name', _workPlaceNameController.text.trim());
    await prefs.setString('setup_anganwadi_name', _anganwadiNameController.text.trim());
    await prefs.setString('setup_state_code', _stateCodeController.text.trim());
    await prefs.setString('setup_district_code', _districtCodeController.text.trim());
    await prefs.setString('setup_taluk_code', _talukCodeController.text.trim());
    await prefs.setString('setup_locality_code', _localityCodeController.text.trim());
    await prefs.setString('setup_area_suffix_code', _areaSuffixCodeController.text.trim());
    await prefs.setString('setup_date_of_entry', _dateOfEntryController.text.trim());
    await prefs.setString('setup_grids', jsonEncode(_grids));
  }

  List<Map<String, String>> _decodeGrids(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map(
            (e) => e.map(
              (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _buildAreaCode() {
    return '${_stateCodeController.text.trim()}-'
        '${_districtCodeController.text.trim()}-'
        '${_talukCodeController.text.trim()}-'
        '${_localityCodeController.text.trim()}-'
        '${_areaSuffixCodeController.text.trim()}';
  }

  void _ensureDemoSampleGrid() {
    if (_isDemoSession) {
      final hasSample = _grids.any((g) => g['isSample'] == 'true');
      if (!hasSample) {
        _grids.insert(0, {
          'gridId': 'demo-sample-grid',
          'samplingUnit': 'Family',
          'state': 'Demo State',
          'district': 'Demo District',
          'taluk': 'Demo Taluk',
          'areaCode': '01-01-01-001-01',
          'isSample': 'true',
        });
      }
      return;
    }
    _grids.removeWhere((g) => g['isSample'] == 'true');
  }

  List<Map<String, String>> _filteredGrids() {
    return _grids
        .where((g) => (g['samplingUnit'] ?? '') == _activeSamplingUnit)
        .toList();
  }

  void _setActiveSamplingUnit(String unit) {
    setState(() {
      _activeSamplingUnit = unit;
      _selectedSamplingUnit = unit;
    });
  }

  String _areaSuffixTypeForSamplingUnit() {
    final unit = _selectedSamplingUnit ?? '';
    final point = _selectedIndividualEntryPoint ?? '';
    if (unit == 'Individual' && point == 'School') return 'school';
    if (unit == 'Individual' && point == 'Anganwadi') return 'anganwadi';
    return 'cluster';
  }

  int _areaSuffixLengthForSamplingUnit() {
    return _areaSuffixTypeForSamplingUnit() == 'cluster' ? 2 : 3;
  }

  String _areaSuffixLabelForSamplingUnit() {
    final type = _areaSuffixTypeForSamplingUnit();
    if (type == 'school') return 'School Code';
    if (type == 'anganwadi') return 'Anganwadi Code';
    return 'Cluster Code';
  }

  bool _isAreaCodeValidParts() {
    return _stateCodeController.text.trim().length == 2 &&
        _districtCodeController.text.trim().length == 2 &&
        _talukCodeController.text.trim().length == 2 &&
        _localityCodeController.text.trim().length == 3 &&
        _areaSuffixCodeController.text.trim().length ==
            _areaSuffixLengthForSamplingUnit();
  }

  String _normalizePart(String value, int len) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    if (digits.length >= len) return digits.substring(digits.length - len);
    return digits.padLeft(len, '0');
  }

  void _normalizeCodeControllers() {
    _stateCodeController.text = _normalizePart(_stateCodeController.text, 2);
    _districtCodeController.text = _normalizePart(_districtCodeController.text, 2);
    _talukCodeController.text = _normalizePart(_talukCodeController.text, 2);
    _localityCodeController.text = _normalizePart(_localityCodeController.text, 3);
    _areaSuffixCodeController.text = _normalizePart(
      _areaSuffixCodeController.text,
      _areaSuffixLengthForSamplingUnit(),
    );
  }

  String _currentLocalityName() {
    final unit = _selectedSamplingUnit ?? '';
    if (unit == 'Family') return _villageController.text.trim();
    if (unit == 'Individual') {
      return _cityVillageController.text.trim();
    }
    return _cityVillageController.text.trim();
  }

  void _setCurrentLocalityName(String value, {String? localityType}) {
    final unit = _selectedSamplingUnit ?? '';
    if (unit == 'Family') {
      _villageController.text = value;
    } else if (unit == 'Individual') {
      _cityVillageController.text = value;
    } else {
      _cityVillageController.text = value;
    }
  }

  void _syncNamesFromCode() {
    if (_isSyncingAreaCode || !_isAreaCodeValidParts()) return;
    final entry = _areaCodeService.findByCodeParts(
      _areaCodeEntries,
      stateCode: _stateCodeController.text.trim(),
      districtCode: _districtCodeController.text.trim(),
      talukCode: _talukCodeController.text.trim(),
      localityCode: _localityCodeController.text.trim(),
      areaSuffixCode: _areaSuffixCodeController.text.trim(),
      areaSuffixType: _areaSuffixTypeForSamplingUnit(),
    );
    if (entry == null) return;

    _isSyncingAreaCode = true;
    _stateController.text = entry.stateName;
    _districtController.text = entry.districtName;
    _talukController.text = entry.talukName;
    _setCurrentLocalityName(entry.localityName, localityType: entry.localityType);
    if (entry.phcArea.isNotEmpty) {
      _phcController.text = entry.phcArea;
    }
    if (entry.clusterName.isNotEmpty) {
      _clusterController.text = entry.clusterName;
    }
    _isSyncingAreaCode = false;
  }

  void _syncCodeFromNames() {
    if (_isSyncingAreaCode) return;
    final entry = _areaCodeService.findByNames(
      _areaCodeEntries,
      stateName: _stateController.text.trim(),
      districtName: _districtController.text.trim(),
      talukName: _talukController.text.trim(),
      localityName: _currentLocalityName(),
      areaSuffixType: _areaSuffixTypeForSamplingUnit(),
    );
    if (entry == null) return;

    _isSyncingAreaCode = true;
    _stateCodeController.text = entry.stateCode;
    _districtCodeController.text = entry.districtCode;
    _talukCodeController.text = entry.talukCode;
    _localityCodeController.text = entry.localityCode;
    _areaSuffixCodeController.text = entry.areaSuffixCode;
    _isSyncingAreaCode = false;
  }

  Widget _codePartField({
    required String label,
    required int maxLength,
    required TextEditingController controller,
  }) {
    return SizedBox(
      width: maxLength == 3 ? 86 : 72,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => _syncNamesFromCode(),
      ),
    );
  }

  List<Widget> _buildSetupFields() {
    final samplingUnit = _selectedSamplingUnit ?? '';
    final isFamily = samplingUnit == 'Family';
    final isPerson = samplingUnit == 'Person';
    final isAnganwadi = samplingUnit == 'Anganwadi';
    final isSchool = samplingUnit == 'School';
    final isWorkPlace = samplingUnit == 'Work Place';
    final isPhcArea = samplingUnit == 'PHC Area';

    final fields = <Widget>[
      TextField(
        controller: _stateController,
        decoration: const InputDecoration(
          labelText: 'State',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => _syncCodeFromNames(),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _districtController,
        decoration: const InputDecoration(
          labelText: 'District',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => _syncCodeFromNames(),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _talukController,
        decoration: const InputDecoration(
          labelText: 'Taluk/Mandal Name',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => _syncCodeFromNames(),
      ),
      const SizedBox(height: 12),
    ];

    if (isFamily || isPerson || isPhcArea) {
      fields.addAll([
        TextField(
          controller: _phcController,
          decoration: const InputDecoration(
            labelText: 'PHC',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (isFamily) {
      fields.addAll([
        TextField(
          controller: _subcentreController,
          decoration: const InputDecoration(
            labelText: 'Subcentre',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _villageController,
          decoration: const InputDecoration(
            labelText: 'Village',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _syncCodeFromNames(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _clusterController,
          decoration: const InputDecoration(
            labelText: 'Cluster',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (isSchool || isWorkPlace || isAnganwadi) {
      fields.addAll([
        TextField(
          controller: _cityVillageController,
          decoration: const InputDecoration(
            labelText: 'Village/City',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _syncCodeFromNames(),
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (isSchool) {
      fields.addAll([
        TextField(
          controller: _schoolNameController,
          decoration: const InputDecoration(
            labelText: 'School Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (isAnganwadi) {
      fields.addAll([
        TextField(
          controller: _anganwadiNameController,
          decoration: const InputDecoration(
            labelText: 'Anganwadi Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (isWorkPlace || isPhcArea) {
      fields.addAll([
        if (isWorkPlace)
          TextField(
            controller: _workPlaceNameController,
            decoration: const InputDecoration(
              labelText: 'Workplace Name',
              border: OutlineInputBorder(),
            ),
          ),
        if (isWorkPlace) const SizedBox(height: 12),
        TextField(
          controller: _clusterController,
          decoration: const InputDecoration(
            labelText: 'Cluster',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
      ]);
    }

    fields.add(
      InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Area Code Preview',
          border: OutlineInputBorder(),
          helperText: 'Format: SS-DD-TT-LLL-XX (Cluster) or SS-DD-TT-LLL-XXX',
        ),
        child: Text(
          '${_stateCodeController.text}-${_districtCodeController.text}-${_talukCodeController.text}-${_localityCodeController.text}-${_areaSuffixCodeController.text}',
        ),
      ),
    );
    fields.add(const SizedBox(height: 12));
    fields.add(
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _codePartField(
              label: 'S',
              maxLength: 2,
              controller: _stateCodeController,
            ),
            const SizedBox(width: 8),
            _codePartField(
              label: 'D',
              maxLength: 2,
              controller: _districtCodeController,
            ),
            const SizedBox(width: 8),
            _codePartField(
              label: 'T',
              maxLength: 2,
              controller: _talukCodeController,
            ),
            const SizedBox(width: 8),
            _codePartField(
              label: 'L',
              maxLength: 3,
            controller: _localityCodeController,
          ),
          const SizedBox(width: 8),
          _codePartField(
            label: 'X',
            maxLength: _areaSuffixLengthForSamplingUnit(),
            controller: _areaSuffixCodeController,
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Sync',
            onPressed: () async {
                _normalizeCodeControllers();
                await _refreshAreaCodeEntries();
                _syncNamesFromCode();
                _syncCodeFromNames();
                if (!mounted) return;
                setState(() {});
              },
              icon: const Icon(Icons.sync),
            ),
          ],
        ),
      ),
    );
    fields.add(const SizedBox(height: 12));
    fields.add(
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CodeGuideScreen()),
                );
                _areaCodeEntries = await _areaCodeService.getEntries();
                _syncNamesFromCode();
              },
              child: const Text('Code Guide'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CodeMasterManagementScreen(),
                  ),
                );
                _areaCodeEntries = await _areaCodeService.getEntries();
                _syncNamesFromCode();
              },
              child: const Text('Manage Codes'),
            ),
          ),
        ],
      ),
    );
    fields.add(
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          '${_areaSuffixLabelForSamplingUnit()}: ${_areaSuffixLengthForSamplingUnit()} digits',
        ),
      ),
    );
    fields.add(const SizedBox(height: 12));
    fields.add(
      TextField(
        controller: _dateOfEntryController,
        readOnly: true,
        onTap: _pickDateOfEntry,
        decoration: const InputDecoration(
          labelText: 'Date of Entry',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
      ),
    );

    return fields;
  }

  List<Widget> _buildLocationFieldsForStepper() {
    final samplingUnit = _selectedSamplingUnit ?? '';
    final isFamily = samplingUnit == 'Family';
    final isIndividual = samplingUnit == 'Individual';
    final isCommunity = samplingUnit == 'Community';
    final entryPoint = _selectedIndividualEntryPoint ?? _individualEntryPoints.first;
    final isAnganwadiPoint = isIndividual && entryPoint == 'Anganwadi';
    final isSchoolPoint = isIndividual && entryPoint == 'School';
    final isWorkplacePoint = isIndividual && entryPoint == 'Workplace';

    final fields = <Widget>[
      TextField(
        controller: _stateController,
        decoration: const InputDecoration(
          labelText: 'State',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => _syncCodeFromNames(),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _districtController,
        decoration: const InputDecoration(
          labelText: 'District',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => _syncCodeFromNames(),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _talukController,
        decoration: const InputDecoration(
          labelText: 'Taluk/Mandal Name',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => _syncCodeFromNames(),
      ),
      const SizedBox(height: 12),
    ];

    if (isFamily || isIndividual) {
      fields.addAll([
        TextField(
          controller: _phcController,
          decoration: const InputDecoration(
            labelText: 'PHC',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (isIndividual) {
      fields.addAll([
        DropdownButtonFormField<String>(
          initialValue: _selectedIndividualEntryPoint,
          decoration: const InputDecoration(
            labelText: 'Individual Entry Place',
            border: OutlineInputBorder(),
          ),
          items: _individualEntryPoints
              .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedIndividualEntryPoint = value;
              _areaSuffixCodeController.clear();
            });
          },
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (isFamily) {
      fields.addAll([
        TextField(
          controller: _subcentreController,
          decoration: const InputDecoration(
            labelText: 'Subcentre',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _villageController,
          decoration: const InputDecoration(
            labelText: 'Village',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _syncCodeFromNames(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _clusterController,
          decoration: const InputDecoration(
            labelText: 'Cluster',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (isIndividual) {
      fields.addAll([
        TextField(
          controller: _cityVillageController,
          decoration: const InputDecoration(
            labelText: 'Village/City',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _syncCodeFromNames(),
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (isSchoolPoint) {
      fields.addAll([
        TextField(
          controller: _schoolNameController,
          decoration: const InputDecoration(
            labelText: 'School Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (isAnganwadiPoint) {
      fields.addAll([
        TextField(
          controller: _anganwadiNameController,
          decoration: const InputDecoration(
            labelText: 'Anganwadi Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (isWorkplacePoint) {
      fields.addAll([
        TextField(
          controller: _workPlaceNameController,
          decoration: const InputDecoration(
            labelText: 'Workplace Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (isCommunity) {
      fields.addAll([
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Community sampling is under development. '
              'Grid can be saved; data collection will be enabled later.',
            ),
          ),
        ),
        const SizedBox(height: 12),
      ]);
    }

    fields.add(
      TextField(
        controller: _dateOfEntryController,
        readOnly: true,
        onTap: _pickDateOfEntry,
        decoration: const InputDecoration(
          labelText: 'Date of Entry',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
      ),
    );
    return fields;
  }

  Future<void> _openStartDataCollectionSetup() async {
    await _refreshAreaCodeEntries();
    if (!mounted) return;
    int currentStep = 0;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget stepBody;
            if (currentStep == 0) {
              stepBody = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSamplingUnit,
                    decoration: const InputDecoration(
                      labelText: 'Sampling Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: _samplingUnits
                        .map(
                          (unit) => DropdownMenuItem<String>(
                            value: unit,
                            child: Text(unit),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedSamplingUnit = value;
                        if (value == 'Individual') {
                          _selectedIndividualEntryPoint ??=
                              _individualEntryPoints.first;
                        } else {
                          _selectedIndividualEntryPoint = null;
                        }
                        _areaSuffixCodeController.clear();
                      });
                      setModalState(() {});
                    },
                  ),
                  if (_selectedSamplingUnit == 'Individual') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedIndividualEntryPoint,
                      decoration: const InputDecoration(
                        labelText: 'Individual Entry Place',
                        border: OutlineInputBorder(),
                      ),
                      items: _individualEntryPoints
                          .map(
                            (unit) => DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedIndividualEntryPoint = value;
                          _areaSuffixCodeController.clear();
                        });
                        setModalState(() {});
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dateOfEntryController,
                    readOnly: true,
                    onTap: _pickDateOfEntry,
                    decoration: const InputDecoration(
                      labelText: 'Date of Entry',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ],
              );
            } else if (currentStep == 1) {
              stepBody = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Area Code Preview',
                      border: OutlineInputBorder(),
                      helperText:
                          'Format: SS-DD-TT-LLL-XX (Cluster) or SS-DD-TT-LLL-XXX',
                    ),
                    child: Text(
                      '${_stateCodeController.text}-${_districtCodeController.text}-${_talukCodeController.text}-${_localityCodeController.text}-${_areaSuffixCodeController.text}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _codePartField(
                          label: 'S',
                          maxLength: 2,
                          controller: _stateCodeController,
                        ),
                        const SizedBox(width: 8),
                        _codePartField(
                          label: 'D',
                          maxLength: 2,
                          controller: _districtCodeController,
                        ),
                        const SizedBox(width: 8),
                        _codePartField(
                          label: 'T',
                          maxLength: 2,
                          controller: _talukCodeController,
                        ),
                        const SizedBox(width: 8),
                        _codePartField(
                          label: 'L',
                          maxLength: 3,
                          controller: _localityCodeController,
                        ),
                        const SizedBox(width: 8),
                        _codePartField(
                          label: 'X',
                          maxLength: _areaSuffixLengthForSamplingUnit(),
                          controller: _areaSuffixCodeController,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Sync',
                          onPressed: () async {
                            _normalizeCodeControllers();
                            await _refreshAreaCodeEntries();
                            _syncNamesFromCode();
                            _syncCodeFromNames();
                            if (!mounted) return;
                            setState(() {});
                            setModalState(() {});
                          },
                          icon: const Icon(Icons.sync),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CodeGuideScreen(),
                              ),
                            );
                            _areaCodeEntries = await _areaCodeService.getEntries();
                            _syncNamesFromCode();
                            setModalState(() {});
                          },
                          child: const Text('Code Guide'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CodeMasterManagementScreen(),
                              ),
                            );
                            _areaCodeEntries = await _areaCodeService.getEntries();
                            _syncNamesFromCode();
                            setModalState(() {});
                          },
                          child: const Text('Manage Codes'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_areaSuffixLabelForSamplingUnit()}: ${_areaSuffixLengthForSamplingUnit()} digits',
                  ),
                ],
              );
            } else if (currentStep == 2) {
              stepBody = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildLocationFieldsForStepper(),
              );
            } else {
              stepBody = Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sampling Unit: ${_selectedSamplingUnit ?? ''}'),
                      if ((_selectedIndividualEntryPoint ?? '').isNotEmpty)
                        Text('Entry Place: ${_selectedIndividualEntryPoint ?? ''}'),
                      Text('State: ${_stateController.text.trim()}'),
                      Text('District: ${_districtController.text.trim()}'),
                      Text('Taluk: ${_talukController.text.trim()}'),
                      Text('Area Code: ${_buildAreaCode()}'),
                      Text('Date: ${_dateOfEntryController.text.trim()}'),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(dialogContext).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Set Grid - Step ${currentStep + 1}/4',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: (currentStep + 1) / 4),
                    const SizedBox(height: 12),
                    stepBody,
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (currentStep > 0)
                          OutlinedButton(
                            onPressed: () {
                              setModalState(() => currentStep -= 1);
                            },
                            child: const Text('Back'),
                          ),
                        const Spacer(),
                        if (currentStep < 3)
                          ElevatedButton(
                            onPressed: () {
                              if (currentStep == 1 && !_isAreaCodeValidParts()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Invalid Area Code. Complete all code parts.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setModalState(() => currentStep += 1);
                            },
                            child: const Text('Next'),
                          )
                        else
                          ElevatedButton(
                            onPressed: () async {
                              if (!_isAreaCodeValidParts()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Invalid Area Code. Use SS-DD-TT-LLL-XX or SS-DD-TT-LLL-XXX.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final messenger = ScaffoldMessenger.of(context);
                              await _saveSetupPreferences();
                              if (!dialogContext.mounted || !mounted) return;
                              setState(() {
                                final gridId =
                                    DateTime.now().millisecondsSinceEpoch.toString();
                                final areaCode = _buildAreaCode();
                                _grids.add({
                                  'gridId': gridId,
                                  'samplingUnit': _selectedSamplingUnit ?? '',
                                  'entryPlace':
                                      _selectedIndividualEntryPoint ?? '',
                                  'state': _stateController.text.trim(),
                                  'district': _districtController.text.trim(),
                                  'taluk': _talukController.text.trim(),
                                  'areaCode': areaCode,
                                });
                              });
                              await _saveSetupPreferences();
                              Navigator.of(dialogContext).pop();
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Set Grid saved.')),
                              );
                            },
                            child: const Text('Save Setup'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CareGrid Dashboard'),
        leadingWidth: 96,
        leading: TextButton(
          onPressed: _openStartDataCollectionSetup,
          child: Text('Set ${_activeSamplingUnit}'),
        ),
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _authService.signOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            )
          else
            TextButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                if (!mounted) return;
                _initializeHome();
              },
              child: const Text('Login'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to CareGrid',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_name != null) Text('User: $_name'),
            if (_organizationName != null) Text('Organization: $_organizationName'),
            if (_role != null)
              Text('Role: ${MedicalRolePolicy.label(_role)} (${_role ?? ''})'),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose Program',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _samplingUnits
                          .map(
                            (unit) => ChoiceChip(
                              label: Text(unit),
                              selected: _activeSamplingUnit == unit,
                              onSelected: (_) => _setActiveSamplingUnit(unit),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (MedicalRolePolicy.canReviewClinical(_role)) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DoctorDashboardScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.medical_services_outlined),
                  label: const Text('Open Doctor Dashboard'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: _filteredGrids().isEmpty
                  ? const Center(
                      child: Text('No grids yet for this program. Tap Set to add.'),
                    )
                  : ListView.separated(
                      itemCount: _filteredGrids().length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final grid = _filteredGrids()[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              grid['areaCode'] ?? '',
                            ),
                            subtitle: Text(
                              'Sampling: ${grid['samplingUnit'] ?? ''} | '
                              '${(grid['entryPlace'] ?? '').isNotEmpty ? 'Entry: ${grid['entryPlace']} | ' : ''}'
                              'Taluk: ${grid['taluk'] ?? ''}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              if ((grid['samplingUnit'] ?? '') == 'Community') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Community workflow is under development.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DataCollectionScreen(
                                    samplingUnit:
                                        grid['samplingUnit'] ?? _samplingUnits.first,
                                    setupData: {
                                      'state': grid['state'] ?? '',
                                      'district': grid['district'] ?? '',
                                      'taluk': grid['taluk'] ?? '',
                                      'areaCode': grid['areaCode'] ?? '',
                                      'entryPlace': grid['entryPlace'] ?? '',
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
            if (MedicalRolePolicy.canOpenAdminPanel(_role))
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminScreen(),
                    ),
                  );
                },
                child: const Text('Admin Panel'),
              ),
          ],
        ),
      ),
    );
  }
}
