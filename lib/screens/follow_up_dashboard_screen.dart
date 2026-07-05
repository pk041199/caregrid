import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/follow_up_service.dart';
import '../services/medical_role_policy.dart';

class FollowUpDashboardScreen extends StatefulWidget {
  const FollowUpDashboardScreen({
    super.key,
    required this.entries,
    required this.samplingUnit,
    required this.setupData,
    this.onEntriesChanged,
    this.onOpenFollowUpForm,
  });

  final List<Map<String, String>> entries;
  final String samplingUnit;
  final Map<String, String> setupData;
  final ValueChanged<List<Map<String, String>>>? onEntriesChanged;
  final Future<bool> Function(Map<String, String> row)? onOpenFollowUpForm;

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
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _selectedDay;
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _showOverdueOnly = false;
  final Set<String> _selectedRowKeys = <String>{};
  static const List<String> _statusFilters = [
    'All',
    'Planned',
    'Doctor Reviewed',
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
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _loadError;
  List<Map<String, String>> _rows = [];
  int _dbPulledCount = 0;
  String _roleLabel = 'Field Collector';
  bool _doctorWorkflow = false;

  @override
  void initState() {
    super.initState();
    final role = _authService.currentUserRole;
    _roleLabel = MedicalRolePolicy.label(role);
    _doctorWorkflow = MedicalRolePolicy.canReviewClinical(role);
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

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

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

  String _rowKey(Map<String, String> row) {
    return row['id'] ?? [
      row['familyId'] ?? '',
      row['memberName'] ?? '',
      row['formId'] ?? '',
      row['followUpDate'] ?? '',
      row['scope'] ?? '',
    ].join('|');
  }

  List<Map<String, String>> _filteredEntries() {
    final now = DateTime.now();
    final from = _fromDate == null ? null : _startOfDay(_fromDate!);
    final to = _toDate == null ? null : _startOfDay(_toDate!);
    final selected = _selectedDay == null ? null : _startOfDay(_selectedDay!);
    final filtered = _rows.where((e) {
      final categoryMatch =
          _selectedFilter == 'All' || (e['formCategory'] ?? '') == _selectedFilter;
      final statusMatch =
          _selectedStatus == 'All' || (e['status'] ?? 'Planned') == _selectedStatus;
      final scopeMatch =
          _selectedScope == 'All' || (e['scope'] ?? 'Individual') == _selectedScope;
      final due = _parseDate(e['followUpDate']);
      final dueDay = due == null ? null : _startOfDay(due);
      final fromMatch =
          from == null || (dueDay != null && !dueDay.isBefore(from));
      final toMatch = to == null || (dueDay != null && !dueDay.isAfter(to));
      final dayMatch = selected == null || (dueDay != null && dueDay == selected);
      final overdueOnlyMatch = !_showOverdueOnly ||
          (due != null && due.isBefore(DateTime.now()) && (e['status'] ?? 'Planned') == 'Planned');
      final formId = (e['formId'] ?? '').trim().toLowerCase();
      final formLane = {'anc', 'pnc', 'new_born'}.contains(formId);
      final laneMatch = _doctorWorkflow
          ? formLane
          : (formLane || !_doctorWorkflow);
      return categoryMatch &&
          statusMatch &&
          scopeMatch &&
          fromMatch &&
          toMatch &&
          dayMatch &&
          overdueOnlyMatch &&
          laneMatch;
    }).toList();
    filtered.sort((a, b) {
      final da = _parseDate(a['followUpDate']) ?? DateTime(now.year + 20);
      final db = _parseDate(b['followUpDate']) ?? DateTime(now.year + 20);
      return da.compareTo(db);
    });
    return filtered;
  }

  Map<String, int> _groupByDateCount(List<Map<String, String>> rows) {
    final map = <String, int>{};
    for (final row in rows) {
      final raw = (row['followUpDate'] ?? '').trim();
      if (raw.isEmpty) continue;
      map[raw] = (map[raw] ?? 0) + 1;
    }
    return Map<String, int>.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Map<String, int> _groupByFormCount(List<Map<String, String>> rows) {
    final map = <String, int>{};
    for (final row in rows) {
      final form = (row['formCategory'] ?? row['formId'] ?? '-').trim();
      if (form.isEmpty) continue;
      map[form] = (map[form] ?? 0) + 1;
    }
    return Map<String, int>.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  int _calendarCountForDay(DateTime day, Map<String, int> dateCounts) {
    final key = _startOfDay(day).toIso8601String().split('T').first;
    return dateCounts[key] ?? 0;
  }

  String _monthLabel(DateTime month) {
    const names = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[month.month - 1]} ${month.year}';
  }

  Widget _buildCalendarSummary(List<Map<String, String>> rows) {
    final dateCounts = _groupByDateCount(rows);
    final formCounts = _groupByFormCount(rows);
    final monthStart = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final offset = monthStart.weekday - 1;
    final totalCells = ((offset + daysInMonth + 6) ~/ 7) * 7;
    final today = _startOfDay(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Follow-ups Calendar',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Previous Month',
                  onPressed: () {
                    setState(() {
                      _calendarMonth =
                          DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(_monthLabel(_calendarMonth)),
                IconButton(
                  tooltip: 'Next Month',
                  onPressed: () {
                    setState(() {
                      _calendarMonth =
                          DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Expanded(child: Center(child: Text('Mon'))),
                Expanded(child: Center(child: Text('Tue'))),
                Expanded(child: Center(child: Text('Wed'))),
                Expanded(child: Center(child: Text('Thu'))),
                Expanded(child: Center(child: Text('Fri'))),
                Expanded(child: Center(child: Text('Sat'))),
                Expanded(child: Center(child: Text('Sun'))),
              ],
            ),
            const SizedBox(height: 4),
            ...List.generate(totalCells ~/ 7, (week) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: List.generate(7, (dow) {
                    final cell = week * 7 + dow;
                    final dayNum = cell - offset + 1;
                    if (dayNum < 1 || dayNum > daysInMonth) {
                      return const Expanded(child: SizedBox(height: 40));
                    }
                    final day = DateTime(
                      _calendarMonth.year,
                      _calendarMonth.month,
                      dayNum,
                    );
                    final count = _calendarCountForDay(day, dateCounts);
                    final isToday = _startOfDay(day) == today;
                    final isSelected =
                        _selectedDay != null && _startOfDay(day) == _startOfDay(_selectedDay!);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedDay = null;
                            } else {
                              _selectedDay = day;
                            }
                          });
                        },
                        child: Container(
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.deepOrange
                                  : isToday
                                      ? Colors.blue
                                      : Colors.black12,
                              width: isSelected ? 1.8 : 1,
                            ),
                            color: isSelected
                                ? Colors.orange.shade100
                                : count > 0
                                    ? Colors.orange.shade50
                                    : Colors.transparent,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$dayNum',
                                style: const TextStyle(fontSize: 11),
                              ),
                              if (count > 0)
                                Text(
                                  '$count due',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
            if (_selectedDay != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Selected Date: ${_selectedDay!.toIso8601String().split('T').first}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() => _selectedDay = null),
                    child: const Text('Clear Day Filter'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'By Form',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: formCounts.entries
                  .map(
                    (e) => Chip(
                      label: Text('${e.key}: ${e.value}'),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _fromDate = picked);
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _toDate = picked);
  }

  void _toggleSelection(Map<String, String> row) {
    final key = _rowKey(row);
    setState(() {
      if (_selectedRowKeys.contains(key)) {
        _selectedRowKeys.remove(key);
      } else {
        _selectedRowKeys.add(key);
      }
    });
  }

  Future<void> _applyBulkAction(String action) async {
    if (_selectedRowKeys.isEmpty) return;

    final selectedRows = _rows.where((row) => _selectedRowKeys.contains(_rowKey(row))).toList();

    if (action == 'completed') {
      setState(() {
        for (final row in selectedRows) {
          row['status'] = 'Completed';
        }
      });
    } else if (action == 'missed') {
      setState(() {
        for (final row in selectedRows) {
          row['status'] = 'Missed';
        }
      });
    } else if (action == 'reschedule') {
      final initial = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked == null || !mounted) return;
      setState(() {
        for (final row in selectedRows) {
          row['followUpDate'] = picked.toIso8601String().split('T').first;
          row['status'] = 'Rescheduled';
        }
      });
    }

    _selectedRowKeys.clear();
    _notifyEntriesChanged();
  }

  Future<void> _openStatusSheet(Map<String, String> row) async {
    await showModalBottomSheet<void>(
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
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Doctor Reviewed':
        return Colors.teal;
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

  Future<void> _openFormOrStatus(Map<String, String> row) async {
    final messenger = ScaffoldMessenger.of(context);
    final opener = widget.onOpenFollowUpForm;
    if (opener == null) {
      await _openStatusSheet(row);
      return;
    }
    final opened = await opener(row);
    if (!mounted) return;
    if (opened) {
      await _markStatus(row, _doctorWorkflow ? 'Doctor Reviewed' : 'Completed');
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open linked follow-up form for this row.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filteredEntries();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-up Dashboard'),
        actions: [
          if (_selectedRowKeys.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: _applyBulkAction,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'completed', child: Text('Mark Completed')),
                const PopupMenuItem(value: 'missed', child: Text('Mark Missed')),
                const PopupMenuItem(value: 'reschedule', child: Text('Reschedule')),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Center(child: Text('Actions')),
              ),
            ),
        ],
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
                    Text('Role: $_roleLabel'),
                    Text(
                      'Grid: ${widget.setupData['state'] ?? '-'}, '
                      '${widget.setupData['district'] ?? '-'}, '
                      '${widget.setupData['taluk'] ?? '-'}',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Field Workflow'),
                          selected: !_doctorWorkflow,
                          onSelected: (_) {
                            setState(() {
                              _doctorWorkflow = false;
                              _selectedStatus = 'All';
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Doctor Workflow'),
                          selected: _doctorWorkflow,
                          onSelected: (_) {
                            setState(() {
                              _doctorWorkflow = true;
                              _selectedStatus = 'All';
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
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
                  const SizedBox(width: 10),
                  FilterChip(
                    label: const Text('Overdue only'),
                    selected: _showOverdueOnly,
                    onSelected: (value) => setState(() => _showOverdueOnly = value),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _pickFromDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      _fromDate == null
                          ? 'From Date'
                          : _fromDate!.toIso8601String().split('T').first,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _pickToDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      _toDate == null
                          ? 'To Date'
                          : _toDate!.toIso8601String().split('T').first,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_fromDate != null || _toDate != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _fromDate = null;
                          _toDate = null;
                        });
                      },
                      child: const Text('Clear Dates'),
                    ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _loadFromDatabase,
                    icon: const Icon(Icons.download_for_offline_outlined),
                    label: const Text('Pull DB'),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Total: ${rows.length}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
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
            _buildCalendarSummary(rows),
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
                        final reviewedBy = (row['reviewedBy'] ?? '').trim();
                        final reviewedAtRaw = (row['reviewedAt'] ?? '').trim();
                        final reviewedAt = reviewedAtRaw.isEmpty
                            ? ''
                            : (DateTime.tryParse(reviewedAtRaw)
                                        ?.toIso8601String()
                                        .split('T')
                                        .first ??
                                    reviewedAtRaw);
                        final selected = _selectedRowKeys.contains(_rowKey(row));
                        return Card(
                          child: ListTile(
                            leading: selected
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : const Icon(Icons.radio_button_unchecked),
                            title: Text(
                              '${row['formCategory'] ?? row['formId'] ?? '-'} | ${row['memberName'] ?? '-'}',
                            ),
                            subtitle: Text(
                              'Family ${row['familyId'] ?? '-'} | '
                              'Follow-up ${row['followUpDate'] ?? '-'} | '
                              'Status $status | Scope $scope'
                              '${reviewedBy.isNotEmpty ? ' | Reviewed by $reviewedBy' : ''}'
                              '${reviewedAt.isNotEmpty ? ' on $reviewedAt' : ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
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
                                IconButton(
                                  tooltip: _doctorWorkflow
                                      ? 'Open for Clinical Review'
                                      : 'Open Follow-up Form',
                                  icon: const Icon(Icons.edit_note_outlined),
                                  onPressed: () => _openFormOrStatus(row),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () {
                              if (_selectedRowKeys.isNotEmpty) {
                                _toggleSelection(row);
                              } else {
                                _openFormOrStatus(row);
                              }
                            },
                            onLongPress: () {
                              _toggleSelection(row);
                              if (_selectedRowKeys.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Bulk actions enabled')),
                                );
                              }
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
