import 'package:flutter/material.dart';
import '../models/workplace_models.dart';
import '../services/workplace_service.dart';
import '../app/routes/route_names.dart';

class WorkplaceDashboardScreen extends StatefulWidget {
  const WorkplaceDashboardScreen({
    super.key,
    required this.workplaceId,
  });

  final String workplaceId;

  @override
  State<WorkplaceDashboardScreen> createState() =>
      _WorkplaceDashboardScreenState();
}

class _WorkplaceDashboardScreenState extends State<WorkplaceDashboardScreen> {
  final WorkplaceService _workplaceService = WorkplaceService();
  late Future<_WorkplaceData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadWorkplaceData();
  }

  Future<_WorkplaceData> _loadWorkplaceData() async {
    try {
      final workplace =
          await _workplaceService.getWorkplace(workplaceId: widget.workplaceId);
      final workers =
          await _workplaceService.getWorkers(workplaceId: widget.workplaceId);
      final stats = await _workplaceService.getScreeningStats(
          workplaceId: widget.workplaceId);

      return _WorkplaceData(
        workplace: workplace,
        totalWorkers: workers.length,
        screeningStats: stats,
      );
    } catch (e) {
      print('Error loading workplace data: $e');
      return _WorkplaceData(
        workplace: null,
        totalWorkers: 0,
        screeningStats: {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Workplace Dashboard')),
      body: FutureBuilder<_WorkplaceData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ??
              _WorkplaceData(
                workplace: null,
                totalWorkers: 0,
                screeningStats: {},
              );

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.workplace != null)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.workplace!.workplaceName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 8),
                          if (data.workplace!.industryType != null)
                            Text('Industry: ${data.workplace!.industryType}'),
                          if (data.workplace!.location != null)
                            Text('📍 ${data.workplace!.location}'),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 24),

                // Overview Stats
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overview',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    data.totalWorkers.toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  SizedBox(height: 4),
                                  Text('Total Workers'),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    (data.screeningStats['with_blood_pressure'] ??
                                            0)
                                        .toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  SizedBox(height: 4),
                                  Text('Screened'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                Text(
                  'Health Screening Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 12),
                _buildScreeningItem(
                  context,
                  label: 'Blood Pressure',
                  completed: data.screeningStats['with_blood_pressure'] ?? 0,
                  total: data.totalWorkers,
                ),
                _buildScreeningItem(
                  context,
                  label: 'Blood Glucose',
                  completed: data.screeningStats['with_glucose'] ?? 0,
                  total: data.totalWorkers,
                ),
                _buildScreeningItem(
                  context,
                  label: 'Respiratory Assessment',
                  completed: data.screeningStats['with_respiratory'] ?? 0,
                  total: data.totalWorkers,
                ),
                _buildScreeningItem(
                  context,
                  label: 'Hearing Assessment',
                  completed: data.screeningStats['with_hearing'] ?? 0,
                  total: data.totalWorkers,
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            RouteNames.workerRegistration,
            arguments: widget.workplaceId,
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Register worker',
      ),
    );
  }

  Widget _buildScreeningItem(
    BuildContext context, {
    required String label,
    required int completed,
    required int total,
  }) {
    final percentage = total > 0 ? ((completed / total) * 100).toStringAsFixed(0) : '0';
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completed / (total > 0 ? total : 1),
                minHeight: 6,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            ),
            SizedBox(height: 4),
            Text(
              '$completed / $total workers',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkplaceData {
  final Workplace? workplace;
  final int totalWorkers;
  final Map<String, int> screeningStats;

  _WorkplaceData({
    required this.workplace,
    required this.totalWorkers,
    required this.screeningStats,
  });
}
