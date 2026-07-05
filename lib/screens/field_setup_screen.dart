import 'package:flutter/material.dart';
import '../models/field_models.dart';
import '../services/auth_service.dart';
import '../services/field_service.dart';
import '../app/routes/route_names.dart';

class FieldSetupScreen extends StatefulWidget {
  const FieldSetupScreen({super.key});

  @override
  State<FieldSetupScreen> createState() => _FieldSetupScreenState();
}

class _FieldSetupScreenState extends State<FieldSetupScreen> {
  final FieldService _fieldService = FieldService();
  final _gridCodeController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _mandalController = TextEditingController();
  final _villageController = TextEditingController();

  late Future<List<FieldGrid>> _gridsFuture;
  bool _isCreatingGrid = false;

  String get _organizationId =>
      AuthService().currentSession?.organizationId ?? 'demo-org';

  @override
  void initState() {
    super.initState();
    _gridsFuture = _loadGrids();
  }

  Future<List<FieldGrid>> _loadGrids() async {
    try {
      return await _fieldService.getGrids(organizationId: _organizationId);
    } catch (e) {
      print('Error loading grids: $e');
      return [];
    }
  }

  Future<void> _createGrid() async {
    if (_gridCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Grid code is required')),
      );
      return;
    }

    setState(() => _isCreatingGrid = true);
    try {
      await _fieldService.createGrid(
        organizationId: _organizationId,
        gridCode: _gridCodeController.text,
        state: _stateController.text,
        district: _districtController.text,
        mandal: _mandalController.text,
        village: _villageController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grid created successfully')),
        );
        _gridCodeController.clear();
        _stateController.clear();
        _districtController.clear();
        _mandalController.clear();
        _villageController.clear();
        setState(() => _gridsFuture = _loadGrids());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingGrid = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Field Setup')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Grid',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _gridCodeController,
                    decoration: InputDecoration(
                      labelText: 'Grid Code *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _stateController,
                    decoration: InputDecoration(
                      labelText: 'State',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _districtController,
                    decoration: InputDecoration(
                      labelText: 'District',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _mandalController,
                    decoration: InputDecoration(
                      labelText: 'Mandal/Taluk',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _villageController,
                    decoration: InputDecoration(
                      labelText: 'Village',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isCreatingGrid ? null : _createGrid,
                    child: _isCreatingGrid
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Create Grid'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Active Grids',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 12),
          FutureBuilder<List<FieldGrid>>(
            future: _gridsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text('No grids yet. Create one to get started.'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final grid = snapshot.data![index];
                  return Card(
                    child: ListTile(
                      title: Text(grid.gridCode),
                      subtitle: Text(
                          '${grid.state ?? ''}, ${grid.district ?? ''}, ${grid.village ?? ''}'),
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          RouteNames.familyRegistration,
                          arguments: grid.id,
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gridCodeController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _mandalController.dispose();
    _villageController.dispose();
    super.dispose();
  }
}
