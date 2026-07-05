import 'package:flutter/material.dart';
import '../models/clinic_models.dart';
import '../services/auth_service.dart';
import '../services/clinic_service.dart';
import '../app/routes/route_names.dart';

class ClinicSelectionScreen extends StatefulWidget {
  const ClinicSelectionScreen({super.key});

  @override
  State<ClinicSelectionScreen> createState() => _ClinicSelectionScreenState();
}

class _ClinicSelectionScreenState extends State<ClinicSelectionScreen> {
  final ClinicService _clinicService = ClinicService();
  final _clinicNameController = TextEditingController();
  final _clinicCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();

  late Future<List<Clinic>> _clinicsFuture;
  bool _isCreating = false;

  String get _organizationId =>
      AuthService().currentSession?.organizationId ?? 'demo-org';

  @override
  void initState() {
    super.initState();
    _clinicsFuture = _loadClinics();
  }

  Future<List<Clinic>> _loadClinics() async {
    try {
      return await _clinicService.getClinics(organizationId: _organizationId);
    } catch (e) {
      print('Error loading clinics: $e');
      return [];
    }
  }

  Future<void> _createClinic() async {
    if (_clinicNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Clinic name is required')),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      await _clinicService.createClinic(
        organizationId: _organizationId,
        clinicName: _clinicNameController.text,
        clinicCode: _clinicCodeController.text,
        address: _addressController.text,
        contactNumber: _contactController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clinic created successfully')),
        );
        _clinicNameController.clear();
        _clinicCodeController.clear();
        _addressController.clear();
        _contactController.clear();
        setState(() => _clinicsFuture = _loadClinics());
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
      appBar: AppBar(title: Text('Clinic')),
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
                    'Create New Clinic',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _clinicNameController,
                    decoration: InputDecoration(
                      labelText: 'Clinic Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _clinicCodeController,
                    decoration: InputDecoration(
                      labelText: 'Clinic Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _contactController,
                    decoration: InputDecoration(
                      labelText: 'Contact Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isCreating ? null : _createClinic,
                    child: _isCreating
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Create Clinic'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Active Clinics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 12),
          FutureBuilder<List<Clinic>>(
            future: _clinicsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text('No clinics yet. Create one to get started.'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final clinic = snapshot.data![index];
                  return Card(
                    child: ListTile(
                      title: Text(clinic.clinicName),
                      subtitle: Text(clinic.address ?? 'No address'),
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          RouteNames.clinicDashboard,
                          arguments: clinic.id,
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
    _clinicNameController.dispose();
    _clinicCodeController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }
}
