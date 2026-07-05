import 'package:flutter/material.dart';
import '../models/school_models.dart';
import '../services/school_service.dart';
import '../app/routes/route_names.dart';

class SchoolDashboardScreen extends StatefulWidget {
  const SchoolDashboardScreen({
    super.key,
    required this.schoolId,
  });

  final String schoolId;

  @override
  State<SchoolDashboardScreen> createState() => _SchoolDashboardScreenState();
}

class _SchoolDashboardScreenState extends State<SchoolDashboardScreen> {
  final SchoolService _schoolService = SchoolService();
  late Future<_SchoolData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadSchoolData();
  }

  Future<_SchoolData> _loadSchoolData() async {
    try {
      final school = await _schoolService.getSchool(schoolId: widget.schoolId);
      final students = await _schoolService.getStudents(schoolId: widget.schoolId);
      final stats = await _schoolService.getScreeningStats(schoolId: widget.schoolId);

      return _SchoolData(
        school: school,
        totalStudents: students.length,
        screeningStats: stats,
      );
    } catch (e) {
      print('Error loading school data: $e');
      return _SchoolData(
        school: null,
        totalStudents: 0,
        screeningStats: {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('School Dashboard')),
      body: FutureBuilder<_SchoolData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ??
              _SchoolData(
                school: null,
                totalStudents: 0,
                screeningStats: {},
              );

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.school != null)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.school!.schoolName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 8),
                          if (data.school!.managementType != null)
                            Text('Type: ${data.school!.managementType}'),
                          if (data.school!.location != null)
                            Text('📍 ${data.school!.location}'),
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
                                    data.totalStudents.toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  SizedBox(height: 4),
                                  Text('Total Students'),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    (data.screeningStats['with_height'] ?? 0)
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
                  'Screening Progress',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 12),
                _buildProgressItem(
                  context,
                  label: 'Height',
                  completed: data.screeningStats['with_height'] ?? 0,
                  total: data.totalStudents,
                ),
                _buildProgressItem(
                  context,
                  label: 'Weight',
                  completed: data.screeningStats['with_weight'] ?? 0,
                  total: data.totalStudents,
                ),
                _buildProgressItem(
                  context,
                  label: 'Vision',
                  completed: data.screeningStats['with_vision'] ?? 0,
                  total: data.totalStudents,
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
            RouteNames.studentRegistration,
            arguments: widget.schoolId,
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Register student',
      ),
    );
  }

  Widget _buildProgressItem(
    BuildContext context, {
    required String label,
    required int completed,
    required int total,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('$completed/$total'),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completed / (total > 0 ? total : 1),
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}

class _SchoolData {
  final School? school;
  final int totalStudents;
  final Map<String, int> screeningStats;

  _SchoolData({
    required this.school,
    required this.totalStudents,
    required this.screeningStats,
  });
}
