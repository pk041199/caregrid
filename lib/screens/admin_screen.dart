import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/medical_role_policy.dart';
import '../services/organization_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final OrganizationService _orgService = OrganizationService();
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();

  bool _isLoading = false;
  bool _isAuthorizing = true;
  bool _isExporting = false;
  bool _canOpenAdmin = false;
  bool _canCreateOrganization = false;
  String _roleLabel = '';
  List<dynamic> _organizations = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final role = await _authService.getUserRole();
    if (!mounted) return;

    _canOpenAdmin = MedicalRolePolicy.canOpenAdminPanel(role);
    _canCreateOrganization = MedicalRolePolicy.canCreateOrganization(role);
    _roleLabel = MedicalRolePolicy.label(role);
    _isAuthorizing = false;
    setState(() {});

    if (_canOpenAdmin) {
      await _loadOrganizations();
    }
  }

  Future<void> _loadOrganizations() async {
    final data = await _orgService.getOrganizations();
    if (!mounted) return;

    setState(() {
      _organizations = data;
    });
  }

  Future<void> _createOrganization() async {
    if (!_canCreateOrganization) return;
    setState(() => _isLoading = true);

    await _orgService.createOrganization(
      name: _nameController.text.trim(),
      type: _typeController.text.trim(),
    );

    _nameController.clear();
    _typeController.clear();

    await _loadOrganizations();

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<List<_LocalExportRow>> _collectLocalExportRows() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('caregrid_')).toList()
      ..sort();
    final rows = <_LocalExportRow>[];

    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) continue;

      dynamic parsed;
      try {
        parsed = jsonDecode(raw);
      } catch (_) {
        continue;
      }

      if (parsed is List) {
        rows.add(
          _LocalExportRow(
            key: key,
            kind: 'list',
            records: parsed.length,
            preview: parsed.isNotEmpty ? parsed.first.toString() : '',
          ),
        );
      } else if (parsed is Map) {
        rows.add(
          _LocalExportRow(
            key: key,
            kind: 'object',
            records: parsed.isEmpty ? 0 : 1,
            preview: parsed.toString(),
          ),
        );
      }
    }
    return rows;
  }

  String _rowsToCsv(List<_LocalExportRow> rows) {
    String esc(String s) => '"${s.replaceAll('"', '""')}"';
    final buffer = StringBuffer();
    buffer.writeln('key,type,records,preview');
    for (final row in rows) {
      final preview = row.preview.length > 120
          ? '${row.preview.substring(0, 120)}...'
          : row.preview;
      buffer.writeln(
        '${esc(row.key)},${esc(row.kind)},${row.records},${esc(preview)}',
      );
    }
    return buffer.toString();
  }

  Future<void> _copyCsvExport() async {
    setState(() => _isExporting = true);
    try {
      final rows = await _collectLocalExportRows();
      final csv = _rowsToCsv(rows);
      await Clipboard.setData(ClipboardData(text: csv));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV summary copied to clipboard.')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _copyJsonBackup() async {
    setState(() => _isExporting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{};
      final keys = prefs.getKeys().where((k) => k.startsWith('caregrid_')).toList()
        ..sort();
      for (final key in keys) {
        final raw = prefs.getString(key);
        if (raw == null || raw.trim().isEmpty) continue;
        try {
          map[key] = jsonDecode(raw);
        } catch (_) {
          map[key] = raw;
        }
      }
      await Clipboard.setData(
        ClipboardData(text: const JsonEncoder.withIndent('  ').convert(map)),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JSON backup copied to clipboard.')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _downloadSummaryPdf() async {
    setState(() => _isExporting = true);
    try {
      final rows = await _collectLocalExportRows();
      final totalRecords = rows.fold<int>(0, (sum, row) => sum + row.records);
      final date = DateTime.now().toIso8601String();
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text(
              'CareGrid Download Summary',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Generated: $date'),
            pw.Text('Rows: ${rows.length}'),
            pw.Text('Records: $totalRecords'),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: const ['Storage Key', 'Type', 'Records'],
              data: rows
                  .map((e) => [e.key, e.kind, e.records.toString()])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      );
      await Printing.layoutPdf(onLayout: (_) async => doc.save());
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthorizing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_canOpenAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('CareGrid Admin Panel')),
        body: const Center(
          child: Text('Access denied. Manager or Creator role required.'),
        ),
      );
    }

    final roleCards = <Map<String, String>>[
      {
        'role': 'Medical Creator',
        'scope': 'Project governance, org setup, role policy',
      },
      {
        'role': 'Program Manager',
        'scope': 'User allocation, operational monitoring, approvals',
      },
      {
        'role': 'Clinical Curator',
        'scope': 'Clinical review, treatment plan curation, quality checks',
      },
      {
        'role': 'Field Collector',
        'scope': 'Primary data capture, follow-up scheduling',
      },
      {
        'role': 'Read-only Viewer',
        'scope': 'Dashboards and reports only',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CareGrid Admin Panel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text('Signed in as $_roleLabel'),
                subtitle: const Text(
                  'Role model is aligned to EpiCollect-style project governance and adapted for medical workflows.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Medical Role Matrix',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...roleCards.map(
              (card) => Card(
                child: ListTile(
                  title: Text(card['role'] ?? ''),
                  subtitle: Text(card['scope'] ?? ''),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Download Setup',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Download-only exports for admin operations (no upload).',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isExporting ? null : _downloadSummaryPdf,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Download PDF Summary'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isExporting ? null : _copyCsvExport,
                          icon: const Icon(Icons.table_chart_outlined),
                          label: const Text('Copy CSV Summary'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isExporting ? null : _copyJsonBackup,
                          icon: const Icon(Icons.data_object_outlined),
                          label: const Text('Copy JSON Backup'),
                        ),
                      ],
                    ),
                    if (_isExporting) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Create Organization',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _nameController,
              enabled: _canCreateOrganization,
              decoration: const InputDecoration(labelText: 'Organization Name'),
            ),
            TextField(
              controller: _typeController,
              enabled: _canCreateOrganization,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 10),
            if (!_canCreateOrganization)
              const Text(
                'Only Medical Creator can create organizations.',
                style: TextStyle(color: Colors.orange),
              ),
            if (_canCreateOrganization)
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _createOrganization,
                      child: const Text('Create'),
                    ),
            const Divider(height: 30),
            const Text(
              'Existing Organizations',
              style: TextStyle(fontSize: 16),
            ),
            ..._organizations.map((org) {
              return ListTile(
                title: Text((org['name'] ?? '').toString()),
                subtitle: Text((org['type'] ?? '').toString()),
              );
            }),
            if (_organizations.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No organizations found.'),
              ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Suggested medical permissions:\n'
                  '- Collector: Create/edit field forms only\n'
                  '- Curator/Doctor: Review and finalize assessment/plan\n'
                  '- Manager: Supervise users and audit completion\n'
                  '- Creator: Manage organizations and global roles',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalExportRow {
  const _LocalExportRow({
    required this.key,
    required this.kind,
    required this.records,
    required this.preview,
  });

  final String key;
  final String kind;
  final int records;
  final String preview;
}
