import 'package:flutter/material.dart';
import '../models/field_models.dart';
import '../services/field_service.dart';
import '../app/routes/route_names.dart';

class FieldDashboardScreen extends StatefulWidget {
  const FieldDashboardScreen({
    super.key,
    required this.gridId,
  });

  final String gridId;

  @override
  State<FieldDashboardScreen> createState() => _FieldDashboardScreenState();
}

class _FieldDashboardScreenState extends State<FieldDashboardScreen> {
  final FieldService _fieldService = FieldService();
  late Future<_GridData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadGridData();
  }

  Future<_GridData> _loadGridData() async {
    try {
      final families = await _fieldService.getFamilies(gridId: widget.gridId);
      int totalMembers = 0;
      for (final family in families) {
        final members =
            await _fieldService.getFamilyMembers(familyId: family.id);
        totalMembers += members.length;
      }

      return _GridData(
        families: families,
        totalMembers: totalMembers,
      );
    } catch (e) {
      print('Error loading grid data: $e');
      return _GridData(families: [], totalMembers: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Grid Overview')),
      body: FutureBuilder<_GridData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? _GridData(families: [], totalMembers: 0);

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                data.families.length.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(color: Colors.green),
                              ),
                              SizedBox(height: 8),
                              Text('Families'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                data.totalMembers.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(color: Colors.blue),
                              ),
                              SizedBox(height: 8),
                              Text('Members'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Families List
                Text(
                  'Registered Families',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 12),
                if (data.families.isEmpty)
                  Center(child: Text('No families registered yet'))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: data.families.length,
                    itemBuilder: (context, index) {
                      final family = data.families[index];
                      return Card(
                        child: ListTile(
                          title: Text(family.familyHeadName),
                          subtitle: Text(
                              'ID: ${family.familyId} | Address: ${family.address ?? 'N/A'}'),
                          trailing: Icon(Icons.arrow_forward),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RouteNames.familyMembers,
                              arguments: family.id,
                            );
                          },
                        ),
                      );
                    },
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
            RouteNames.familyRegistration,
            arguments: widget.gridId,
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Register new family',
      ),
    );
  }
}

class _GridData {
  final List<Family> families;
  final int totalMembers;

  _GridData({
    required this.families,
    required this.totalMembers,
  });
}
