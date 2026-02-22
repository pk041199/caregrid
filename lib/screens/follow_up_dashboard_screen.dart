import 'package:flutter/material.dart';

class FollowUpDashboardScreen extends StatefulWidget {
  const FollowUpDashboardScreen({
    super.key,
    required this.entries,
    required this.samplingUnit,
    required this.setupData,
  });

  final List<Map<String, String>> entries;
  final String samplingUnit;
  final Map<String, String> setupData;

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
    final filtered = widget.entries.where((e) {
      if (_selectedFilter == 'All') return true;
      return (e['formCategory'] ?? '') == _selectedFilter;
    }).toList();
    filtered.sort((a, b) {
      final da = _parseDate(a['followUpDate']) ?? DateTime(now.year + 20);
      final db = _parseDate(b['followUpDate']) ?? DateTime(now.year + 20);
      return da.compareTo(db);
    });
    return filtered;
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
                const Spacer(),
                Text(
                  'Total: ${rows.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
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
                        return Card(
                          child: ListTile(
                            title: Text(
                              '${row['formCategory'] ?? row['formId'] ?? '-'} | ${row['memberName'] ?? '-'}',
                            ),
                            subtitle: Text(
                              'Family ${row['familyId'] ?? '-'} | Follow-up ${row['followUpDate'] ?? '-'}',
                            ),
                            trailing: Text(
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
