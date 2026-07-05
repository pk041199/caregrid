import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/school_service.dart';

class SchoolRegistrationScreen extends StatefulWidget {
  const SchoolRegistrationScreen({
    super.key,
    required this.schoolId,
  });

  final String schoolId;

  @override
  State<SchoolRegistrationScreen> createState() =>
      _SchoolRegistrationScreenState();
}

class _SchoolRegistrationScreenState extends State<SchoolRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _classController = TextEditingController();
  final _sectionController = TextEditingController();
  DateTime? _selectedDob;
  bool _isSaving = false;
  final SchoolService _schoolService = SchoolService();

  String get _organizationId =>
      AuthService().currentSession?.organizationId ?? 'demo-org';

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _classController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _registerStudent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _schoolService.registerStudent(
        schoolId: widget.schoolId,
        organizationId: _organizationId,
        name: _nameController.text.trim(),
        studentId: _idController.text.trim().isEmpty
            ? null
            : _idController.text.trim(),
        dob: _selectedDob,
        gender: _genderController.text.trim().isEmpty
            ? null
            : _genderController.text.trim(),
        className: _classController.text.trim().isEmpty
            ? null
            : _classController.text.trim(),
        section: _sectionController.text.trim().isEmpty
            ? null
            : _sectionController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student registered successfully.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to register student: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Student')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter student name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
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
                controller: _classController,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sectionController,
                decoration: const InputDecoration(
                  labelText: 'Section',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _registerStudent,
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Student'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
