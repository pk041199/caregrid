import 'package:flutter/material.dart';
import '../models/anganwadi_models.dart';
import '../services/anganwadi_service.dart';
import '../app/routes/route_names.dart';

class AnganwadiDashboardScreen extends StatefulWidget {
  const AnganwadiDashboardScreen({
    super.key,
    required this.anganwadiId,
  });

  final String anganwadiId;

  @override
  State<AnganwadiDashboardScreen> createState() =>
      _AnganwadiDashboardScreenState();
}

class _AnganwadiDashboardScreenState extends State<AnganwadiDashboardScreen> {
  final AnganwadiService _anganwadiService = AnganwadiService();
  late Future<_AnganwadiData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAnganwadiData();
  }

  Future<_AnganwadiData> _loadAnganwadiData() async {
    try {
      final anganwadi =
          await _anganwadiService.getAnganwadi(anganwadiId: widget.anganwadiId);
      final counts = await _anganwadiService.getBeneficiaryCounts(
          anganwadiId: widget.anganwadiId);

      return _AnganwadiData(
        anganwadi: anganwadi,
        childCount: counts['children'] ?? 0,
        adolescentCount: counts['adolescents'] ?? 0,
        motherCount: counts['mothers'] ?? 0,
      );
    } catch (e) {
      print('Error loading anganwadi data: $e');
      return _AnganwadiData(
        anganwadi: null,
        childCount: 0,
        adolescentCount: 0,
        motherCount: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Anganwadi Dashboard')),
      body: FutureBuilder<_AnganwadiData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ??
              _AnganwadiData(
                anganwadi: null,
                childCount: 0,
                adolescentCount: 0,
                motherCount: 0,
              );

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.anganwadi != null)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.anganwadi!.anganwadiName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 8),
                          if (data.anganwadi!.village != null)
                            Text('📍 ${data.anganwadi!.village}'),
                          if (data.anganwadi!.workerName != null)
                            Text('👤 ${data.anganwadi!.workerName}'),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 24),

                // Beneficiary Type Cards
                Text(
                  'Beneficiaries',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 12),
                _buildBeneficiaryCard(
                  context,
                  title: 'Children',
                  count: data.childCount,
                  color: Colors.blue,
                  icon: Icons.child_care,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      RouteNames.anganwadiBeneficiaryType,
                      arguments: {'anganwadiId': widget.anganwadiId, 'type': 'child'},
                    );
                  },
                ),
                SizedBox(height: 12),
                _buildBeneficiaryCard(
                  context,
                  title: 'Adolescents',
                  count: data.adolescentCount,
                  color: Colors.orange,
                  icon: Icons.person,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      RouteNames.anganwadiBeneficiaryType,
                      arguments: {'anganwadiId': widget.anganwadiId, 'type': 'adolescent'},
                    );
                  },
                ),
                SizedBox(height: 12),
                _buildBeneficiaryCard(
                  context,
                  title: 'Mothers',
                  count: data.motherCount,
                  color: Colors.pink,
                  icon: Icons.woman,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      RouteNames.anganwadiBeneficiaryType,
                      arguments: {'anganwadiId': widget.anganwadiId, 'type': 'mother'},
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBeneficiaryCard(
    BuildContext context, {
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$count registered',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnganwadiData {
  final Anganwadi? anganwadi;
  final int childCount;
  final int adolescentCount;
  final int motherCount;

  _AnganwadiData({
    required this.anganwadi,
    required this.childCount,
    required this.adolescentCount,
    required this.motherCount,
  });
}
