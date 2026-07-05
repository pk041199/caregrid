import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({
    super.key,
    this.onSignOut,
  });

  final VoidCallback? onSignOut;

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  bool _loading = true;
  String? _error;
  final List<_PatientRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _loading = true;
      _error = null;
      _records.clear();
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((k) => k.startsWith('caregrid_') && k.endsWith('_families'));
      for (final key in keys) {
        final raw = prefs.getString(key) ?? '';
        if (raw.trim().isEmpty) continue;
        final decoded = jsonDecode(raw);
        if (decoded is! List) continue;
        for (final familyRaw in decoded) {
          if (familyRaw is! Map) continue;
          final family = familyRaw.map((k, v) => MapEntry(k.toString(), v));
          final familyId = (family['familyId'] ?? '').toString();
          final members = family['members'];
          if (members is! List) continue;
          for (final memberRaw in members) {
            if (memberRaw is! Map) continue;
            final member = memberRaw.map((k, v) => MapEntry(k.toString(), (v ?? '').toString()));
            _records.add(
              _PatientRecord(
                grid: _gridLabel(key),
                familyId: familyId,
                name: member['fullName'] ?? '',
                age: member['age'] ?? '',
                gender: member['gender'] ?? '',
                nextFollowUp: member['nextFollowUpDate'] ?? '',
                historyCount: _historyCount(member['clinicalHistoryNcdEntries'] ?? ''),
              ),
            );
          }
        }
      }
      _records.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      _error = 'Failed to load patient records: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _historyCount(String raw) {
    if (raw.trim().isEmpty) return 0;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.length;
    } catch (_) {}
    return 0;
  }

  String _gridLabel(String storageKey) {
    final label = storageKey
        .replaceFirst('caregrid_', '')
        .replaceFirst('_families', '')
        .replaceAll('_', ' ')
        .trim();
    if (label.isEmpty) return 'CareGrid';
    return label
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  void _requestConsult(_PatientRecord record) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Consult request queued for ${record.name}.'),
      ),
    );
  }

  void _startLiveConsult(_PatientRecord record) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Live consult needs realtime/video service connection.'),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: const Text(
          'No downloaded patient data is available on this device yet.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CareGrid Patient'),
        actions: [
          IconButton(
            onPressed: _loadRecords,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          if (widget.onSignOut != null)
            IconButton(
              onPressed: widget.onSignOut,
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _records.isEmpty
                    ? _emptyState()
                    : ListView.separated(
                        itemCount: _records.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final record = _records[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    record.name.isEmpty ? 'Patient' : record.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Care grid: ${record.grid}'),
                                  Text('Family ID: ${record.familyId}'),
                                  Text('Age/Gender: ${record.age} ${record.gender}'.trim()),
                                  Text('Doctor entries: ${record.historyCount}'),
                                  Text(
                                    'Next follow-up: ${record.nextFollowUp.isEmpty ? '-' : record.nextFollowUp}',
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _requestConsult(record),
                                        icon: const Icon(Icons.assignment_outlined),
                                        label: const Text('Request Consult'),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _startLiveConsult(record),
                                        icon: const Icon(Icons.video_call_outlined),
                                        label: const Text('Live Doctor'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _PatientRecord {
  const _PatientRecord({
    required this.grid,
    required this.familyId,
    required this.name,
    required this.age,
    required this.gender,
    required this.nextFollowUp,
    required this.historyCount,
  });

  final String grid;
  final String familyId;
  final String name;
  final String age;
  final String gender;
  final String nextFollowUp;
  final int historyCount;
}
