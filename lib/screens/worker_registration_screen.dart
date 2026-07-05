import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/workplace_service.dart';

class WorkerRegistrationScreen extends StatefulWidget {
  const WorkerRegistrationScreen({
    super.key,
    required this.workplaceId,
  });

  final String workplaceId;

  @override
  State<WorkerRegistrationScreen> createState() =>
      _WorkerRegistrationScreenState();
}

class _WorkerRegistrationScreenState extends State<WorkerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _occupationController = TextEditingController();
  final _jobRoleController = TextEditingController();
  final _yearsController = TextEditingController();
  DateTime? _selectedDob;
  bool _isSaving = false;
  final WorkplaceService _workplaceService = WorkplaceService();

  String get _organizationId =>
      AuthService().currentSession?.organizationId ?? 'demo-org';

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _occupationController.dispose();
    _jobRoleController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _registerWorker() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _workplaceService.registerWorker(
        workplaceId: widget.workplaceId,
        organizationId: _organizationId,
        name: _nameController.text.trim(),
        workerId: _idController.text.trim().isEmpty
            ? null
            : _idController.text.trim(),
        dob: _selectedDob,
        gender: _genderController.text.trim().isEmpty
            ? null
            : _genderController.text.trim(),
        occupation: _occupationController.text.trim().isEmpty
            ? null
            : _occupationController.text.trim(),
        jobRole: _jobRoleController.text.trim().isEmpty
            ? null
            : _jobRoleController.text.trim(),
        yearsOfExposure: double.tryParse(_yearsController.text.trim()),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker registered successfully.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to register worker: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Worker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Worker Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter worker name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'Worker ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        border: OutlineInputBorder(),
                      ),
                      onTap: _pickDob,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _pickDob,
                    child: const Text('Pick'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _genderController,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _occupationController,
                decoration: const InputDecoration(
                  labelText: 'Occupation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jobRoleController,
                decoration: const InputDecoration(
                  labelText: 'Job Role',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yearsController,
                decoration: const InputDecoration(
                  labelText: 'Years of Exposure',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _registerWorker,
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Worker'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
