import 'package:flutter/material.dart';
import '../app/app_mode.dart';
import '../app/routes/route_names.dart';
import '../services/auth_service.dart';
import '../services/field_service.dart';
import '../services/clinic_service.dart';
import '../services/anganwadi_service.dart';
import '../services/school_service.dart';
import '../services/workplace_service.dart';
import '../services/unified_followup_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.appMode,
  });

  final CareGridAppMode appMode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FieldService _fieldService = FieldService();
  final ClinicService _clinicService = ClinicService();
  final AnganwadiService _anganwadiService = AnganwadiService();
  final SchoolService _schoolService = SchoolService();
  final WorkplaceService _workplaceService = WorkplaceService();
  final UnifiedFollowUpService _followUpService = UnifiedFollowUpService();

  late Future<_DashboardStats> _statsFuture;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<_DashboardStats> _loadStats() async {
    try {
      final session = _authService.currentSession;
      if (session == null) return _DashboardStats.empty();

      final orgId = session.organizationId;

      final fieldGrids = await _fieldService.getGrids(organizationId: orgId);
      final clinics = await _clinicService.getClinics(organizationId: orgId);
      final anganwadis =
          await _anganwadiService.getAnganwadis(organizationId: orgId);
      final schools = await _schoolService.getSchools(organizationId: orgId);
      final workplaces =
          await _workplaceService.getWorkplaces(organizationId: orgId);
      final followUps =
          await _followUpService.getFollowUpsDashboard(organizationId: orgId);
      final todayFollowUps =
          await _followUpService.getTodayFollowUpCount(organizationId: orgId);
      final overdueFollowUps =
          await _followUpService.getOverdueFollowUps(organizationId: orgId);

      return _DashboardStats(
        fieldGridCount: fieldGrids.length,
        clinicCount: clinics.length,
        anganwadiCount: anganwadis.length,
        schoolCount: schools.length,
        workplaceCount: workplaces.length,
        totalFollowUps: followUps.length,
        todayFollowUps: todayFollowUps,
        overdueFollowUps: overdueFollowUps.length,
      );
    } catch (e) {
      debugPrint('Error loading stats: $e');
      return _DashboardStats.empty();
    }
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);
    try {
      await Future.delayed(Duration(seconds: 2));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data synced successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen(appMode: widget.appMode)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _authService.currentSession;

    if (session == null) {
      return LoginScreen(appMode: widget.appMode);
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CareGrid'),
            Text(
              session.organizationName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        elevation: 2,
        actions: [
          if (_isSyncing)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.cloud_upload),
              tooltip: 'Sync data',
              onPressed: _syncData,
            ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<_DashboardStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data ?? _DashboardStats.empty();

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${session.fullName}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Role: ${session.role}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                Text(
                  'Select a Module',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    _buildSiteCard(
                      context,
                      icon: Icons.agriculture,
                      title: 'Field / HDSS',
                      count: stats.fieldGridCount,
                      subtitle: 'Family grids',
                      description: 'Register families and map field coverage.',
                      color: Colors.green,
                      onTap: () =>
                          Navigator.pushNamed(context, RouteNames.fieldSetup),
                    ),
                    _buildSiteCard(
                      context,
                      icon: Icons.local_hospital,
                      title: 'Clinic',
                      count: stats.clinicCount,
                      subtitle: 'Clinic sites',
                      description: 'Track visits, referrals, and clinical follow-ups.',
                      color: Colors.blue,
                      onTap: () => Navigator.pushNamed(
                          context, RouteNames.clinicSelection),
                    ),
                    _buildSiteCard(
                      context,
                      icon: Icons.child_care,
                      title: 'Anganwadi',
                      count: stats.anganwadiCount,
                      subtitle: 'Beneficiary groups',
                      description: 'Manage children, adolescents, and mothers.',
                      color: Colors.orange,
                      onTap: () => Navigator.pushNamed(
                          context, RouteNames.anganwadiSelection),
                    ),
                    _buildSiteCard(
                      context,
                      icon: Icons.school,
                      title: 'School',
                      count: stats.schoolCount,
                      subtitle: 'School sites',
                      description: 'Support student registration and school screening.',
                      color: Colors.purple,
                      onTap: () => Navigator.pushNamed(
                          context, RouteNames.schoolSelection),
                    ),
                    _buildSiteCard(
                      context,
                      icon: Icons.work,
                      title: 'Workplace',
                      count: stats.workplaceCount,
                      subtitle: 'Occupational sites',
                      description: 'Monitor worker registration and screenings.',
                      color: Colors.teal,
                      onTap: () => Navigator.pushNamed(
                          context, RouteNames.workplaceSelection),
                    ),
                    _buildSiteCard(
                      context,
                      icon: Icons.assignment,
                      title: 'Follow-ups',
                      count: stats.todayFollowUps,
                      subtitle: '${stats.overdueFollowUps} overdue',
                      description: 'Handle planned, due today, and overdue follow-ups.',
                      color: Colors.red,
                      onTap: () => Navigator.pushNamed(
                          context, RouteNames.unifiedFollowUp),
                    ),
                    _buildSiteCard(
                      context,
                      icon: Icons.insights,
                      title: 'Reports',
                      count: stats.totalFollowUps,
                      subtitle: 'Overview',
                      description: 'Review completion trends and site performance.',
                      color: Colors.amber,
                      onTap: () => Navigator.pushNamed(context, RouteNames.reports),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today at a glance',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildQuickStat(
                              context,
                              label: 'Sites',
                              value: (stats.fieldGridCount +
                                      stats.clinicCount +
                                      stats.anganwadiCount +
                                      stats.schoolCount +
                                      stats.workplaceCount)
                                  .toString(),
                              icon: Icons.location_on_outlined,
                              color: Colors.blue,
                            ),
                            _buildQuickStat(
                              context,
                              label: 'Today',
                              value: stats.todayFollowUps.toString(),
                              icon: Icons.today,
                              color: Colors.orange,
                            ),
                            _buildQuickStat(
                              context,
                              label: 'Overdue',
                              value: stats.overdueFollowUps.toString(),
                              icon: Icons.warning_amber_rounded,
                              color: Colors.red,
                            ),
                            _buildQuickStat(
                              context,
                              label: 'Sync',
                              value: _isSyncing ? 'Syncing' : 'Ready',
                              icon: _isSyncing
                                  ? Icons.sync
                                  : Icons.cloud_done_outlined,
                              color: _isSyncing ? Colors.orange : Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSiteCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
    String? subtitle,
    String? description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                ],
              ),
              SizedBox(height: 14),
              Text(
                '$count',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
              ],
              if (description != null) ...[
                SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Open →',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: 140,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.16),
              child: Icon(icon, color: color, size: 16),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _DashboardStats {
  final int fieldGridCount;
  final int clinicCount;
  final int anganwadiCount;
  final int schoolCount;
  final int workplaceCount;
  final int totalFollowUps;
  final int todayFollowUps;
  final int overdueFollowUps;

  _DashboardStats({
    required this.fieldGridCount,
    required this.clinicCount,
    required this.anganwadiCount,
    required this.schoolCount,
    required this.workplaceCount,
    required this.totalFollowUps,
    required this.todayFollowUps,
    required this.overdueFollowUps,
  });

  factory _DashboardStats.empty() => _DashboardStats(
        fieldGridCount: 0,
        clinicCount: 0,
        anganwadiCount: 0,
        schoolCount: 0,
        workplaceCount: 0,
        totalFollowUps: 0,
        todayFollowUps: 0,
        overdueFollowUps: 0,
      );
}
