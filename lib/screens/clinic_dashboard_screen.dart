import 'package:flutter/material.dart';
import '../models/clinic_models.dart';
import '../services/clinic_service.dart';
import '../app/routes/route_names.dart';

class ClinicDashboardScreen extends StatefulWidget {
  const ClinicDashboardScreen({
    super.key,
    required this.clinicId,
  });

  final String clinicId;

  @override
  State<ClinicDashboardScreen> createState() => _ClinicDashboardScreenState();
}

class _ClinicDashboardScreenState extends State<ClinicDashboardScreen> {
  final ClinicService _clinicService = ClinicService();
  late Future<_ClinicData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadClinicData();
  }

  Future<_ClinicData> _loadClinicData() async {
    try {
      final clinic = await _clinicService.getClinic(clinicId: widget.clinicId);
      final visits = await _clinicService.getClinicVisits(clinicId: widget.clinicId);
      final todayCount = await _clinicService.getTodayVisitCount(
          clinicId: widget.clinicId);
      final monthlyCount = await _clinicService.getMonthlyVisitCount(
          clinicId: widget.clinicId);

      return _ClinicData(
        clinic: clinic,
        totalVisits: visits.length,
        todayVisits: todayCount,
        monthlyVisits: monthlyCount,
      );
    } catch (e) {
      print('Error loading clinic data: $e');
      return _ClinicData(
        clinic: null,
        totalVisits: 0,
        todayVisits: 0,
        monthlyVisits: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Clinic Dashboard')),
      body: FutureBuilder<_ClinicData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? _ClinicData(
            clinic: null,
            totalVisits: 0,
            todayVisits: 0,
            monthlyVisits: 0,
          );

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.clinic != null)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.clinic!.clinicName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 8),
                          Text('${data.clinic!.address}'),
                          if (data.clinic!.contactNumber != null)
                            Text('📞 ${data.clinic!.contactNumber}'),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 24),

                // Stats Grid
                GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      context,
                      title: 'Today',
                      value: data.todayVisits.toString(),
                      color: Colors.blue,
                    ),
                    _buildStatCard(
                      context,
                      title: 'This Month',
                      value: data.monthlyVisits.toString(),
                      color: Colors.green,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Total',
                      value: data.totalVisits.toString(),
                      color: Colors.purple,
                    ),
                  ],
                ),
                SizedBox(height: 24),

                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        RouteNames.clinicRegistration,
                        arguments: widget.clinicId,
                      );
                    },
                    icon: Icon(Icons.person_add),
                    label: Text('Register Individual'),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        RouteNames.clinicForms,
                        arguments: widget.clinicId,
                      );
                    },
                    icon: Icon(Icons.assignment),
                    label: Text('Open Forms'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClinicData {
  final Clinic? clinic;
  final int totalVisits;
  final int todayVisits;
  final int monthlyVisits;

  _ClinicData({
    required this.clinic,
    required this.totalVisits,
    required this.todayVisits,
    required this.monthlyVisits,
  });
}
