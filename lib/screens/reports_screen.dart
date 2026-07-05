import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/clinic_service.dart';
import '../services/field_service.dart';
import '../services/school_service.dart';
import '../services/unified_followup_service.dart';
import '../services/workplace_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _fieldService = FieldService();
  final _clinicService = ClinicService();
  final _schoolService = SchoolService();
  final _workplaceService = WorkplaceService();
  final _followUpService = UnifiedFollowUpService();
  late Future<Map<String, dynamic>> _reportFuture;

  String get _organizationId =>
      AuthService().currentSession?.organizationId ?? 'demo-org';

  @override
  void initState() {
    super.initState();
    _reportFuture = _loadReports();
  }

  Future<Map<String, dynamic>> _loadReports() async {
    final grids = await _fieldService.getGrids(organizationId: _organizationId);
    final clinics = await _clinicService.getClinics(organizationId: _organizationId);
    final schools = await _schoolService.getSchools(organizationId: _organizationId);
    final workplaces = await _workplaceService.getWorkplaces(organizationId: _organizationId);
    final followUps = await _followUpService.getFollowUpsDashboard(
      organizationId: _organizationId,
    );
    final stats = await _followUpService.getFollowUpStats(
      organizationId: _organizationId,
    );

    return {
      'grids': grids.length,
      'clinics': clinics.length,
      'schools': schools.length,
      'workplaces': workplaces.length,
      'followUps': followUps.length,
      'stats': stats,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Insights')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? {};
          final stats = data['stats'] as dynamic;
          final cards = [
            _StatCard(
              title: 'Field grids',
              value: '${data['grids'] ?? 0}',
              subtitle: 'Registered field grids',
              icon: Icons.grid_on,
              color: Colors.teal,
            ),
            _StatCard(
              title: 'Clinics',
              value: '${data['clinics'] ?? 0}',
              subtitle: 'Operational clinics',
              icon: Icons.local_hospital,
              color: Colors.blue,
            ),
            _StatCard(
              title: 'Schools',
              value: '${data['schools'] ?? 0}',
              subtitle: 'Registered schools',
              icon: Icons.school,
              color: Colors.orange,
            ),
            _StatCard(
              title: 'Workplaces',
              value: '${data['workplaces'] ?? 0}',
              subtitle: 'Registered workplaces',
              icon: Icons.work,
              color: Colors.purple,
            ),
          ];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Follow-up summary', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Planned: ${stats?.totalPlanned ?? 0} • Completed: ${stats?.totalCompleted ?? 0} • Overdue: ${stats?.totalOverdue ?? 0}'),
                      const SizedBox(height: 8),
                      Text('Completion rate: ${(stats?.completionRate ?? 0).toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: cards,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live data status', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Follow-ups in current organization: ${data['followUps'] ?? 0}'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.16),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
