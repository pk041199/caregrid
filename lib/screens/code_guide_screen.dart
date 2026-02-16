import 'package:flutter/material.dart';
import '../services/area_code_service.dart';
import 'code_master_management_screen.dart';

class CodeGuideScreen extends StatefulWidget {
  const CodeGuideScreen({super.key});

  @override
  State<CodeGuideScreen> createState() => _CodeGuideScreenState();
}

class _CodeGuideScreenState extends State<CodeGuideScreen> {
  final AreaCodeService _service = AreaCodeService();
  List<AreaCodeEntry> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _service.getEntries();
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Area Code Guide'),
        actions: [
          TextButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CodeMasterManagementScreen()),
              );
              await _load();
            },
            child: const Text('Manage Codes'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Area Code Structure',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('Format: SS-DD-TT-LLL-XX / SS-DD-TT-LLL-XXX'),
            const Text('SS = State code (2 digits)'),
            const Text('DD = District code (2 digits)'),
            const Text('TT = Taluk/Mandal code (2 digits)'),
            const Text('LLL = Locality code (3 digits, village/city only)'),
            const Text('Suffix = Cluster code (2 digits) or School/Anganwadi code (3 digits)'),
            const Text('Cluster is maintained below locality for logistics use.'),
            const SizedBox(height: 12),
            const Text(
              'Code Master',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _rows.length,
                      itemBuilder: (context, index) {
                        final row = _rows[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              '${row.areaCode} (${row.localityType}, ${row.areaSuffixType})',
                            ),
                          subtitle: Text(
                            '${row.stateName} > ${row.districtName} > '
                            '${row.talukName} > ${row.localityName}\n'
                            'PHC: ${row.phcArea.isEmpty ? '-' : row.phcArea} | '
                            'Cluster: ${row.clusterName.isEmpty ? '-' : row.clusterName}',
                          ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
