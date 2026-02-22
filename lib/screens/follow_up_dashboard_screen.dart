import 'package:flutter/material.dart';

import '../services/follow_up_service.dart';

class FollowUpDashboardScreen extends StatefulWidget {
  const FollowUpDashboardScreen({
    super.key,
    required this.entries,
    required this.samplingUnit,
    required this.setupData,
    this.onEntriesChanged,
  });

  final List<Map<String, String>> entries;
  final String samplingUnit;
  final Map<String, String> setupData;
  final ValueChanged<List<Map<String, String>>>? onEntriesChanged;

  @override
  State<FollowUpDashboardScreen> createState() => _FollowUpDashboardScreenState();
}

class _FollowUpDashboardScreenState extends State<FollowUpDashboardScreen> {
  static const List<String> _filters = [
    'All',
    'ANC',
    'PNC',
    'New Born',
    'Under-5',
    'NCD',
  ];

  String _selectedFilter = 'All';
  String _selectedStatus = 'All';
  String _selectedScope = 'All';
  static const List<String> _statusFilters = [
    'All',
    'Planned',
    'Completed',
    'Missed',
    'Rescheduled',
  ];
  static const List<String> _scopeFilters = [
    'All',
    'Individual',
    'Family',
  ];
  final FollowUpService _followUpService = FollowUpService();
  bool _isLoading = true;
  String? _loadError;
  List<Map<String, String>> _rows = [];
  int _dbPulledCount = 0;

  @override
  void initState() {
    super.initState();
    _rows = _mergeUnique(widget.entries, const <Map<String, String>>[]);
    _loadFromDatabase();
  }

  void _notifyEntriesChanged() {
    widget.onEntriesChanged?.call(
      _rows.map((e) => Map<String, String>.from(e)).toList(),
    );
  }

  Future<void> _loadFromDatabase() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final dbRows = await _followUpService.fetchPlannedFollowUps(
        areaCode: (widget.setupData['areaCode'] ?? '').trim(),
        samplingUnit: widget.samplingUnit,
      );

      if (!mounted) return;
      setState(() {
        _rows = _mergeUnique(widget.entries, dbRows);
        _dbPulledCount = dbRows.length;
      });
      _notifyEntriesChanged();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not pull follow-ups from database. Showing local reminders.';
        _rows = _mergeUnique(widget.entries, const <Map<String, String>>[]);
        _dbPulledCount = 0;
      });
      _notifyEntriesChanged();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, String>> _mergeUnique(
    List<Map<String, String>> localRows,
    List<Map<String, String>> dbRows,
  ) {
    final seen = <String>{};
    final merged = <Map<String, String>>[];
    for (final row in [...dbRows, ...localRows]) {
      final key = [
        row['familyId'] ?? '',
        row['memberName'] ?? '',
        row['formId'] ?? '',
        row['followUpDate'] ?? '',
        row['scope'] ?? '',
      ].join('|');
      if (seen.contains(key)) continue;
      seen.add(key);
      merged.add(Map<String, String>.from(row));
    }
    return merged;
  }

  DateTime? _parseDate(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  String _dueBadge(DateTime? followDate) {
    if (followDate == null) return 'No Date';
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final dueDate = DateTime(followDate.year, followDate.month, followDate.day);
    final diff = dueDate.difference(todayDate).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due Today';
    return 'Upcoming';
  }

  List<Map<String, String>> _filteredEntries() {
    final now = DateTime.now();
    final filtered = _rows.where((e) {
      final categoryMatch =
          _selectedFilter == 'All' || (e['formCategory'] ?? '') == _selectedFilter;
      final statusMatch =
          _selectedStatus == 'All' || (e['status'] ?? 'Planned') == _selectedStatus;
      final scopeMatch =
          _selectedScope == 'All' || (e['scope'] ?? 'Individual') == _selectedScope;
      return categoryMatch && statusMatch && scopeMatch;
    }).toList();
    filtered.sort((a, b) {
      final da = _parseDate(a['followUpDate']) ?? DateTime(now.year + 20);
      final db = _parseDate(b['followUpDate']) ?? DateTime(now.year + 20);
      return da.compareTo(db);
    });
    return filtered;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Missed':
        return Colors.red;
      case 'Rescheduled':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  Future<void> _markStatus(
    Map<String, String> row,
    String status,
  ) async {
    setState(() {
      row['status'] = status;
    });
    _notifyEntriesChanged();
  }

  Future<void> _reschedule(Map<String, String> row) async {
    final initial = _parseDate(row['followUpDate']) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      row['followUpDate'] = picked.toIso8601String().split('T').first;
      row['status'] = 'Rescheduled';
    });
    _notifyEntriesChanged();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filteredEntries();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-up Dashboard'),
      ),
      body: Padding(
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
                    Text('Area Code: ${widget.setupData['areaCode'] ?? '-'}'),
                    Text(
                      'Grid: ${widget.setupData['state'] ?? '-'}, '
                      '${widget.setupData['district'] ?? '-'}, '
                      '${widget.setupData['taluk'] ?? '-'}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: _filters
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedFilter = v);
                  },
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: _statusFilters
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedStatus = v);
                  },
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedScope,
                  items: _scopeFilters
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedScope = v);
                  },
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _loadFromDatabase,
                  icon: const Icon(Icons.download_for_offline_outlined),
                  label: const Text('Pull DB'),
                ),
                Text(
                  'Total: ${rows.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Pulled from DB: $_dbPulledCount',
              style: TextStyle(
                color: _dbPulledCount > 0 ? Colors.green : Colors.black54,
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: LinearProgressIndicator(),
              ),
            if (_loadError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _loadError!,
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: rows.isEmpty
                  ? const Center(
                      child: Text('No follow-up plans found for this grid.'),
                    )
                  : ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, i) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final followDate = _parseDate(row['followUpDate']);
                        final badge = _dueBadge(followDate);
                        final status = row['status'] ?? 'Planned';
                        final scope = row['scope'] ?? 'Individual';
                        return Card(
                          child: ListTile(
                            title: Text(
                              '${row['formCategory'] ?? row['formId'] ?? '-'} | ${row['memberName'] ?? '-'}',
                            ),
                            subtitle: Text(
                              'Family ${row['familyId'] ?? '-'} | '
                              'Follow-up ${row['followUpDate'] ?? '-'} | '
                              'Status $status | Scope $scope',
                            ),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  badge,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: badge == 'Overdue'
                                        ? Colors.red
                                        : badge == 'Due Today'
                                            ? Colors.orange
                                            : Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _statusColor(status),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              showModalBottomSheet<void>(
                                context: context,
                                builder: (ctx) {
                                  return SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Wrap(
                                        children: [
                                          ListTile(
                                            title: const Text('Mark Completed'),
                                            onTap: () {
                                              Navigator.pop(ctx);
                                              _markStatus(row, 'Completed');
                                            },
                                          ),
                                          ListTile(
                                            title: const Text('Mark Missed'),
                                            onTap: () {
                                              Navigator.pop(ctx);
                                              _markStatus(row, 'Missed');
                                            },
                                          ),
                                          ListTile(
                                            title: const Text('Reschedule'),
                                            onTap: () async {
                                              Navigator.pop(ctx);
                                              await _reschedule(row);
                                            },
                                          ),
                                          ListTile(
                                            title: const Text('Reset to Planned'),
                                            onTap: () {
                                              Navigator.pop(ctx);
                                              _markStatus(row, 'Planned');
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
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
