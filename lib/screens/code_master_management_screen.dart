import 'package:flutter/material.dart';
import '../services/area_code_service.dart';

class CodeMasterManagementScreen extends StatefulWidget {
  const CodeMasterManagementScreen({super.key});

  @override
  State<CodeMasterManagementScreen> createState() =>
      _CodeMasterManagementScreenState();
}

class _CodeMasterManagementScreenState extends State<CodeMasterManagementScreen> {
  final AreaCodeService _service = AreaCodeService();
  List<AreaCodeEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _service.getEntries();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _openEditor([AreaCodeEntry? existing]) async {
    final sCode = TextEditingController(text: existing?.stateCode ?? '');
    final dCode = TextEditingController(text: existing?.districtCode ?? '');
    final tCode = TextEditingController(text: existing?.talukCode ?? '');
    final lCode = TextEditingController(text: existing?.localityCode ?? '');
    final suffixCode = TextEditingController(text: existing?.areaSuffixCode ?? '');
    final sName = TextEditingController(text: existing?.stateName ?? '');
    final dName = TextEditingController(text: existing?.districtName ?? '');
    final tName = TextEditingController(text: existing?.talukName ?? '');
    final lName = TextEditingController(text: existing?.localityName ?? '');
    final phcArea = TextEditingController(text: existing?.phcArea ?? '');
    final clusterName = TextEditingController(text: existing?.clusterName ?? '');
    String suffixType = existing?.areaSuffixType.isNotEmpty == true
        ? existing!.areaSuffixType
        : 'cluster';
    String localityType = existing?.localityType.isNotEmpty == true
        ? existing!.localityType
        : 'village';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Code Entry' : 'Edit Code Entry'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: sCode, decoration: const InputDecoration(labelText: 'State Code (2)')),
                TextField(controller: dCode, decoration: const InputDecoration(labelText: 'District Code (2)')),
                TextField(controller: tCode, decoration: const InputDecoration(labelText: 'Taluk Code (2)')),
                TextField(controller: lCode, decoration: const InputDecoration(labelText: 'Locality Code (3)')),
                TextField(
                  controller: suffixCode,
                  decoration: const InputDecoration(labelText: 'Code Suffix'),
                ),
                TextField(controller: sName, decoration: const InputDecoration(labelText: 'State Name')),
                TextField(controller: dName, decoration: const InputDecoration(labelText: 'District Name')),
                TextField(controller: tName, decoration: const InputDecoration(labelText: 'Taluk Name')),
                TextField(controller: lName, decoration: const InputDecoration(labelText: 'Locality Name')),
                TextField(controller: phcArea, decoration: const InputDecoration(labelText: 'PHC Area (optional)')),
                TextField(controller: clusterName, decoration: const InputDecoration(labelText: 'Cluster Name (logistics)')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: localityType,
                  items: const [
                    DropdownMenuItem(value: 'village', child: Text('Village')),
                    DropdownMenuItem(value: 'city', child: Text('City')),
                  ],
                  onChanged: (value) {
                    if (value != null) localityType = value;
                  },
                  decoration: const InputDecoration(labelText: 'Locality Type'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: suffixType,
                  items: const [
                    DropdownMenuItem(value: 'cluster', child: Text('Cluster (2 digits)')),
                    DropdownMenuItem(value: 'school', child: Text('School Code (3 digits)')),
                    DropdownMenuItem(value: 'anganwadi', child: Text('Anganwadi Code (3 digits)')),
                  ],
                  onChanged: (value) {
                    if (value != null) suffixType = value;
                  },
                  decoration: const InputDecoration(labelText: 'Suffix Type'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final s = sCode.text.trim();
                final d = dCode.text.trim();
                final t = tCode.text.trim();
                final l = lCode.text.trim();
                final c = suffixCode.text.trim();
                final namesOk = sName.text.trim().isNotEmpty &&
                    dName.text.trim().isNotEmpty &&
                    tName.text.trim().isNotEmpty &&
                    lName.text.trim().isNotEmpty;
                final suffixLen = suffixType == 'cluster' ? 2 : 3;
                final codesOk = RegExp(r'^\d{1,2}$').hasMatch(s) &&
                    RegExp(r'^\d{1,2}$').hasMatch(d) &&
                    RegExp(r'^\d{1,2}$').hasMatch(t) &&
                    RegExp(r'^\d{1,3}$').hasMatch(l) &&
                    RegExp('^\\d{1,$suffixLen}\$').hasMatch(c);

                if (!codesOk || !namesOk) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter valid codes (S/D/T 1-2 digits, L 1-3 digits, suffix by type) and all names.',
                      ),
                    ),
                  );
                  return;
                }

                final entry = AreaCodeEntry(
                  stateCode: s.padLeft(2, '0'),
                  districtCode: d.padLeft(2, '0'),
                  talukCode: t.padLeft(2, '0'),
                  localityCode: l.padLeft(3, '0'),
                  areaSuffixCode: c,
                  areaSuffixType: suffixType,
                  stateName: sName.text.trim(),
                  districtName: dName.text.trim(),
                  talukName: tName.text.trim(),
                  localityName: lName.text.trim(),
                  localityType: localityType,
                  phcArea: phcArea.text.trim(),
                  clusterName: clusterName.text.trim(),
                );
                await _service.upsert(entry);
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                await _load();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    sCode.dispose();
    dCode.dispose();
    tCode.dispose();
    lCode.dispose();
    suffixCode.dispose();
    sName.dispose();
    dName.dispose();
    tName.dispose();
    lName.dispose();
    phcArea.dispose();
    clusterName.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Code Master Management'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openEditor,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final e = _entries[index];
                return ListTile(
                  title: Text('${e.areaCode} (${e.localityType}, ${e.areaSuffixType})'),
                  subtitle: Text(
                    '${e.stateName} > ${e.districtName} > ${e.talukName} > '
                    '${e.localityName}\nPHC: ${e.phcArea.isEmpty ? '-' : e.phcArea} | '
                    'Cluster: ${e.clusterName.isEmpty ? '-' : e.clusterName}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _openEditor(e),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () async {
                          await _service.deleteByAreaCode(e.areaCode);
                          await _load();
                        },
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
