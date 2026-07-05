import 'package:flutter/material.dart';
import '../models/workplace_models.dart';
import '../services/auth_service.dart';
import '../services/workplace_service.dart';
import '../app/routes/route_names.dart';

class WorkplaceSelectionScreen extends StatefulWidget {
  const WorkplaceSelectionScreen({super.key});

  @override
  State<WorkplaceSelectionScreen> createState() =>
      _WorkplaceSelectionScreenState();
}

class _WorkplaceSelectionScreenState extends State<WorkplaceSelectionScreen> {
  final WorkplaceService _workplaceService = WorkplaceService();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _industryController = TextEditingController();
  final _locationController = TextEditingController();

  late Future<List<Workplace>> _workplacesFuture;
  bool _isCreating = false;

  String get _organizationId =>
      AuthService().currentSession?.organizationId ?? 'demo-org';

  @override
  void initState() {
    super.initState();
    _workplacesFuture = _loadWorkplaces();
  }

  Future<List<Workplace>> _loadWorkplaces() async {
    try {
      return await _workplaceService.getWorkplaces(organizationId: _organizationId);
    } catch (e) {
      print('Error loading workplaces: $e');
      return [];
    }
  }

  Future<void> _createWorkplace() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Workplace name is required')),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      await _workplaceService.createWorkplace(
        organizationId: _organizationId,
        workplaceName: _nameController.text,
        workplaceCode: _codeController.text,
        industryType: _industryController.text,
        location: _locationController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Workplace created successfully')),
        );
        _nameController.clear();
        _codeController.clear();
        _industryController.clear();
        _locationController.clear();
        setState(() => _workplacesFuture = _loadWorkplaces());
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
      appBar: AppBar(title: Text('Workplace')),
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
                    'Create New Workplace',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Workplace Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Workplace Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _industryController,
                    decoration: InputDecoration(
                      labelText: 'Industry Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isCreating ? null : _createWorkplace,
                    child: _isCreating
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Create Workplace'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Active Workplaces',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 12),
          FutureBuilder<List<Workplace>>(
            future: _workplacesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text('No workplaces yet. Create one to get started.'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final workplace = snapshot.data![index];
                  return Card(
                    child: ListTile(
                      title: Text(workplace.workplaceName),
                      subtitle: Text(workplace.industryType ?? 'Unknown'),
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          RouteNames.workplaceDashboard,
                          arguments: workplace.id,
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
    _industryController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
