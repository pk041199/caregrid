import 'package:flutter/material.dart';
import '../models/school_models.dart';
import '../services/auth_service.dart';
import '../services/school_service.dart';
import '../app/routes/route_names.dart';

class SchoolSelectionScreen extends StatefulWidget {
  const SchoolSelectionScreen({super.key});

  @override
  State<SchoolSelectionScreen> createState() => _SchoolSelectionScreenState();
}

class _SchoolSelectionScreenState extends State<SchoolSelectionScreen> {
  final SchoolService _schoolService = SchoolService();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _managementController = TextEditingController();
  final _locationController = TextEditingController();

  late Future<List<School>> _schoolsFuture;
  bool _isCreating = false;

  String get _organizationId =>
      AuthService().currentSession?.organizationId ?? 'demo-org';

  @override
  void initState() {
    super.initState();
    _schoolsFuture = _loadSchools();
  }

  Future<List<School>> _loadSchools() async {
    try {
      return await _schoolService.getSchools(organizationId: _organizationId);
    } catch (e) {
      print('Error loading schools: $e');
      return [];
    }
  }

  Future<void> _createSchool() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('School name is required')),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      await _schoolService.createSchool(
        organizationId: _organizationId,
        schoolName: _nameController.text,
        schoolCode: _codeController.text,
        managementType: _managementController.text,
        location: _locationController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('School created successfully')),
        );
        _nameController.clear();
        _codeController.clear();
        _managementController.clear();
        _locationController.clear();
        setState(() => _schoolsFuture = _loadSchools());
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
      appBar: AppBar(title: Text('School')),
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
                    'Create New School',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'School Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'School Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _managementController,
                    decoration: InputDecoration(
                      labelText: 'Management Type',
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
                    onPressed: _isCreating ? null : _createSchool,
                    child: _isCreating
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Create School'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Active Schools',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 12),
          FutureBuilder<List<School>>(
            future: _schoolsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text('No schools yet. Create one to get started.'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final school = snapshot.data![index];
                  return Card(
                    child: ListTile(
                      title: Text(school.schoolName),
                      subtitle: Text(school.location ?? 'No location'),
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          RouteNames.schoolDashboard,
                          arguments: school.id,
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
    _managementController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
