import 'dart:math';

import 'package:flutter/material.dart';

import '../services/sync_service.dart';

class DataCollectionScreen extends StatelessWidget {
  const DataCollectionScreen({
    super.key,
    required this.samplingUnit,
    required this.setupData,
  });

  final String samplingUnit;
  final Map<String, String> setupData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Collection')),
      body: DataCollectionSection(
        samplingUnit: samplingUnit,
        setupData: setupData,
      ),
    );
  }
}

class DataCollectionSection extends StatefulWidget {
  const DataCollectionSection({
    super.key,
    required this.samplingUnit,
    required this.setupData,
  });

  final String samplingUnit;
  final Map<String, String> setupData;

  @override
  State<DataCollectionSection> createState() => DataCollectionSectionState();
}

class DataCollectionSectionState extends State<DataCollectionSection> {
  final SyncService _syncService = SyncService();
  final List<Map<String, dynamic>> _familyEntries = [];
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

  bool get isUploading => _isUploading;

  Future<void> uploadEntries() => _uploadEntries();

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
    final linkedFamilyIdController = TextEditingController();
    final memberCountController = TextEditingController();
    final members = <Map<String, String>?>[];
    String familyEntryType = 'New';

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
                              _familyEntries.add({
                                'familyUuid': _generateUuid(),
                                'familyId': familyId,
                                'familyLocation': familyLocationController.text.trim(),
                                'qrValue': 'caregrid://family/$familyId',
                                'familyType': normalizedType,
                                'linkedFamilyId': linkedFamilyId,
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
      linkedFamilyIdController,
      memberCountController,
    ]);
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
                          title: Text(family['familyId']?.toString() ?? ''),
                          subtitle: Text(
                            'Type: ${family['familyType'] ?? 'New'} | '
                            'Members: ${family['memberCount'] ?? '0'} | '
                            'Location: ${(family['familyLocation'] ?? '').toString().isEmpty ? '-' : family['familyLocation']}',
                          ),
                          children: members
                              .map<Widget>(
                                (m) => ListTile(
                                  title: Text(m['fullName'] ?? ''),
                                  subtitle: Text(
                                    '${m['relationship'] ?? '-'} | '
                                    '${m['sex'] ?? '-'} | '
                                    'Age ${m['age'] ?? '-'} | '
                                    'Income ${m['monthlyIncome']?.isEmpty == true ? '-' : m['monthlyIncome']} | '
                                    'PID ${m['personUuid'] ?? '-'}',
                                  ),
                                ),
                              )
                              .toList()
                            ..add(
                              ListTile(
                                title: const Text('Linked Family ID'),
                                subtitle: Text(
                                  (family['linkedFamilyId'] ?? '').toString().isEmpty
                                      ? '-'
                                      : family['linkedFamilyId'].toString(),
                                ),
                              ),
                            )
                            ..add(
                              ListTile(
                                title: const Text('Family UUID'),
                                subtitle: Text(family['familyUuid']?.toString() ?? '-'),
                              ),
                            )
                            ..add(
                              ListTile(
                                title: const Text('QR Link Value'),
                                subtitle: Text(family['qrValue']?.toString() ?? '-'),
                              ),
                            )
                            ..add(
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'GPS tagging will be captured in revisit.',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.my_location),
                                      label: const Text('GPS Tagging'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Status update will be captured in revisit.',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.flag_outlined),
                                      label: const Text('Status'),
                                    ),
                                  ],
                                ),
                              ),
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
