import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'form_viewer_screen.dart';
import 'follow_up_dashboard_screen.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Collection'),
        actions: [
          TextButton.icon(
            onPressed: _openFollowUpDashboard,
            icon: const Icon(Icons.event_note_outlined),
            label: const Text('Follow-ups'),
          ),
          TextButton.icon(
            onPressed: () async {
              final state = _sectionKey.currentState;
              if (state == null) return;
              await state.uploadEntries();
            },
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Upload'),
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
    'assets/forms/nutritional_history_family.json',
    'assets/forms/environmental_history_family.json',
  ];

  static const List<String> _memberFormAssets = [
    'assets/forms/clinical_history.json',
    'assets/forms/anc.json',
    'assets/forms/pnc.json',
    'assets/forms/new_born.json',
    'assets/forms/under_5.json',
    'assets/forms/ncd.json',
    'assets/forms/diet_recall_24h_individual.json',
  ];

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _seedSampleFamilyEntry();
  }

  void _seedSampleFamilyEntry() {
    if (_familyEntries.isNotEmpty) return;
    final areaCode = (widget.setupData['areaCode'] ?? 'NA')
        .replaceAll('-', '')
        .replaceAll(' ', '');
    final sampleFamilyId = 'FAM-$areaCode-001';
    final sampleFamilyUuid = _generateUuid();
    final sampleQr = 'https://caregrid.app/family/$sampleFamilyUuid';
    _familyEntries.add({
      'familyUuid': sampleFamilyUuid,
      'familyId': sampleFamilyId,
      'familyLocation': 'Sample Street, Ward 3',
      'gps': '',
      'qrValue': sampleQr,
      'familyType': 'New',
      'linkedFamilyId': '',
      'gpsCaptured': false,
      'familyStatus': 'Active',
      'memberCount': '2',
      'members': [
        {
          'personUuid': _generateUuid(),
          'fullName': 'Sample Head',
          'relationship': 'Head',
          'sex': 'Male',
          'dob': '1990-01-01',
          'age': '34',
          'maritalStatus': 'Married',
          'workStatus': 'Employed',
          'monthlyIncome': '15000',
          'status': 'Alive',
          'clinicalHistory': 'No known conditions.',
        },
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
          'clinicalHistory': '',
        },
      ],
    });
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

  void _addRevisitEntry({
    required String familyId,
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
      'familyId': familyId,
      'memberName': memberName,
      'formId': formId,
      'formTitle': formTitle,
      'formCategory': category,
      'followUpDate': followUpDate,
    });
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
    return 'FAM-$areaCode-$suffix';
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

    _disposeControllersAfterTransition([fullName, dob, monthlyIncome]);
    return result;
  }

  Future<void> _openAddFamilySheet() async {
    final familyIdController = TextEditingController(text: _generateFamilyId());
    final familyLocationController = TextEditingController();
    final gpsController = TextEditingController();
    final linkedFamilyIdController = TextEditingController();
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
                      const Text(
                        'Add Family Entry',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: familyIdController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Family Unique ID (Auto)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                      TextField(
                        controller: familyLocationController,
                        decoration: const InputDecoration(
                          labelText: 'Family Location (House/Street/Landmark)',
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
                      if (familyEntryType == 'Migrant' || familyEntryType == 'Split')
                        const SizedBox(height: 12),
                      if (familyEntryType == 'Migrant' || familyEntryType == 'Split')
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
                      const SizedBox(height: 12),
                      if (count > 0)
                        const Text(
                          'Add demographic details for each member:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: count <= 0
                            ? const Center(
                                child: Text(
                                  'Enter number of family members to generate add buttons.',
                                ),
                              )
                            : ListView.builder(
                                itemCount: members.length,
                                itemBuilder: (context, index) {
                                  final member = members[index];
                                  final isAdded = member != null;
                                  return Card(
                                    child: ListTile(
                                      title: Text('Member ${index + 1}'),
                                      subtitle: Text(
                                        isAdded
                                            ? '${member['fullName']} | ${member['sex']} | Age ${member['age']}'
                                            : 'Not added yet',
                                      ),
                                      trailing: ElevatedButton(
                                        onPressed: () async {
                                          final result = await _openMemberDialog(
                                            memberIndex: index,
                                            initial: members[index],
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
                              ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (count <= 0) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Enter valid number of family members.'),
                                ),
                              );
                              return;
                            }
                            if (familyEntryType == 'Split' &&
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
                            final filledMembers = members.where((m) => m != null).length;
                            if (filledMembers != count) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please add all $count members before saving.',
                                  ),
                                ),
                              );
                              return;
                            }
                            setState(() {
                              final familyId = familyIdController.text.trim();
                              final linkedFamilyId = linkedFamilyIdController.text.trim();
                              final normalizedType = familyEntryType == 'Migrant' &&
                                      linkedFamilyId.isEmpty
                                  ? 'New'
                                  : familyEntryType;
                              final familyUuid = _generateUuid();
                              final qrValue =
                                  'https://caregrid.app/family/$familyUuid';
                              _familyEntries.add({
                                'familyUuid': familyUuid,
                                'familyId': familyId,
                                'familyLocation': familyLocationController.text.trim(),
                                'gps': gpsController.text.trim(),
                                'qrValue': qrValue,
                                'familyType': normalizedType,
                                'linkedFamilyId': linkedFamilyId,
                                'gpsCaptured': gpsController.text.trim().isNotEmpty,
                                'allowGpsUpdate': false,
                                'familyStatus':
                                    normalizedType == 'Migrant' ? 'Migrated' : 'Active',
                                'memberCount': count.toString(),
                                'members': members.cast<Map<String, String>>(),
                              });
                            });
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Save Family Entry'),
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

  Future<void> _openClinicalHistoryDialog({
    required Map<String, String> member,
  }) async {
    final controller =
        TextEditingController(text: member['clinicalHistory'] ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clinical History'),
          content: TextField(
            controller: controller,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
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
                  member['clinicalHistory'] = controller.text.trim();
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    _disposeControllersAfterTransition([controller]);
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
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sampling Unit: ${widget.samplingUnit}'),
                  Text('State: ${widget.setupData['state'] ?? '-'}'),
                  Text('District: ${widget.setupData['district'] ?? '-'}'),
                  Text('Taluk/Mandal: ${widget.setupData['taluk'] ?? '-'}'),
                  Text('Area Code: ${widget.setupData['areaCode'] ?? '-'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Saved Family Entries: ${_familyEntries.length}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _openAddFamilySheet,
                icon: const Icon(Icons.add),
                label: const Text('Add Entry'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _familyEntries.isEmpty
                ? const Center(
                    child: Text('No family entries yet. Click Add Entry to start.'),
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
                                      formId: (result?['formId'] ?? form['id'] ?? '').toString(),
                                      formTitle: (result?['formTitle'] ?? form['title'] ?? '').toString(),
                                      followUpDate: follow,
                                    );
                                    setState(() {});
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
                                      break;
                                    case 'status_migrated':
                                      setState(() {
                                        family['familyStatus'] = 'Migrated';
                                      });
                                      break;
                                    case 'status_dissolved':
                                      setState(() {
                                        family['familyStatus'] = 'Dissolved';
                                      });
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
                              title: const Text('Family Location'),
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
                                  'Status ${m['status'] ?? 'Alive'}',
                                ),
                                onTap: () => _openClinicalHistoryDialog(member: m),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'History',
                                      onPressed: () =>
                                          _openClinicalHistoryDialog(member: m),
                                      icon: const Icon(Icons.history),
                                    ),
                                      IconButton(
                                        tooltip: 'Forms',
                                        onPressed: () => _openFormList(
                                          title: 'Member Forms',
                                          assets: _memberFormAssets,
                                          entityLabel:
                                              '${m['fullName'] ?? ''} (${family['familyId'] ?? ''})',
                                          contextData: {
                                            'ancHistory': m['ancHistory'],
                                            'ancBaseline': m['ancBaseline'],
                                          },
                                          suggestedFormIds:
                                              (m['ncdActive'] == 'true')
                                                  ? ['diet_recall_24h']
                                                  : const [],
                                          onSelect: (form, result) {
                                            final formId =
                                                (result?['formId'] ?? form['id'] ?? '').toString();
                                            if (formId == 'ncd') {
                                              setState(() {
                                                m['ncdActive'] = 'true';
                                              });
                                            }
                                            if (formId == 'anc' && result != null) {
                                              final history = (m['ancHistory'] as List<dynamic>? ??
                                                      <dynamic>[])
                                                  .toList();
                                              history.add(result);
                                              m['ancHistory'] = jsonEncode(history);
                                              final baseline =
                                                  (result['ancBaseline'] as Map<String, dynamic>? ??
                                                          const <String, dynamic>{})
                                                      .map(
                                                (k, v) => MapEntry(k, (v ?? '').toString()),
                                              );
                                              m['ancBaseline'] = jsonEncode(baseline);
                                            }
                                            final followForNcd =
                                                _resolveFollowUpDate(form, result);
                                            _addRevisitEntry(
                                              familyId: (family['familyId'] ?? '').toString(),
                                              memberName: (m['fullName'] ?? '').toString(),
                                              formId: formId,
                                              formTitle: (result?['formTitle'] ?? form['title'] ?? '').toString(),
                                              followUpDate: followForNcd,
                                            );
                                            setState(() {});
                                          },
                                        ),
                                        icon: const Icon(Icons.article_outlined),
                                      ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        setState(() {
                                          m['status'] = value;
                                        });
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
                          ]
                            ..add(
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _addMemberToFamily(family),
                                    icon: const Icon(Icons.person_add),
                                    label: const Text('Add Member'),
                                  ),
                                ),
                              ),
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
