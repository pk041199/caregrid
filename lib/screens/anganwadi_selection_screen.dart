import 'package:flutter/material.dart';
import '../models/anganwadi_models.dart';
import '../services/anganwadi_service.dart';
import '../services/auth_service.dart';
import '../app/routes/route_names.dart';

class AnganwadiSelectionScreen extends StatefulWidget {
  const AnganwadiSelectionScreen({super.key});

  @override
  State<AnganwadiSelectionScreen> createState() =>
      _AnganwadiSelectionScreenState();
}

class _AnganwadiSelectionScreenState extends State<AnganwadiSelectionScreen> {
  final AnganwadiService _anganwadiService = AnganwadiService();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _villageController = TextEditingController();
  final _supervisorController = TextEditingController();
  final _workerController = TextEditingController();

  late Future<List<Anganwadi>> _anganwadiFuture;
  bool _isCreating = false;

  String get _organizationId =>
      AuthService().currentSession?.organizationId ?? 'demo-org';

  @override
  void initState() {
    super.initState();
    _anganwadiFuture = _loadAnganwadis();
  }

  Future<List<Anganwadi>> _loadAnganwadis() async {
    try {
      return await _anganwadiService.getAnganwadis(organizationId: _organizationId);
    } catch (e) {
      print('Error loading anganwadis: $e');
      return [];
    }
  }

  Future<void> _createAnganwadi() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anganwadi name is required')),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      await _anganwadiService.createAnganwadi(
        organizationId: _organizationId,
        anganwadiName: _nameController.text,
        anganwadiCode: _codeController.text,
        village: _villageController.text,
        supervisor: _supervisorController.text,
        workerName: _workerController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anganwadi created successfully')),
        );
        _nameController.clear();
        _codeController.clear();
        _villageController.clear();
        _supervisorController.clear();
        _workerController.clear();
        setState(() => _anganwadiFuture = _loadAnganwadis());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Anganwadi')),
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
                    'Create New Anganwadi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Anganwadi Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Code',
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
                  SizedBox(height: 12),
                  TextField(
                    controller: _supervisorController,
                    decoration: InputDecoration(
                      labelText: 'Supervisor Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _workerController,
                    decoration: InputDecoration(
                      labelText: 'Worker Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isCreating ? null : _createAnganwadi,
                    child: _isCreating
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Create Anganwadi'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Active Anganwadis',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 12),
          FutureBuilder<List<Anganwadi>>(
            future: _anganwadiFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text('No anganwadis yet. Create one to get started.'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final anganwadi = snapshot.data![index];
                  return Card(
                    child: ListTile(
                      title: Text(anganwadi.anganwadiName),
                      subtitle: Text(anganwadi.village ?? 'Unknown village'),
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          RouteNames.anganwadiDashboard,
                          arguments: anganwadi.id,
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
    _nameController.dispose();
    _codeController.dispose();
    _villageController.dispose();
    _supervisorController.dispose();
    _workerController.dispose();
    super.dispose();
  }
}
