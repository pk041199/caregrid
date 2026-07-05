import 'package:flutter/material.dart';
import '../services/anganwadi_service.dart';
import '../services/auth_service.dart';

class AnganwadiRegistrationScreen extends StatefulWidget {
  const AnganwadiRegistrationScreen({
    super.key,
    required this.anganwadiId,
    required this.beneficiaryType,
  });

  final String anganwadiId;
  final String beneficiaryType;

  @override
  State<AnganwadiRegistrationScreen> createState() =>
      _AnganwadiRegistrationScreenState();
}

class _AnganwadiRegistrationScreenState
    extends State<AnganwadiRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _secondaryController = TextEditingController();
  final _numericController = TextEditingController();
  DateTime? _selectedDob;
  bool _isSaving = false;
  final AnganwadiService _anganwadiService = AnganwadiService();

  String get _organizationId =>
      AuthService().currentSession?.organizationId ?? 'demo-org';

  String get _title {
    switch (widget.beneficiaryType.toLowerCase()) {
      case 'child':
        return 'Register Child';
      case 'adolescent':
        return 'Register Adolescent';
      case 'mother':
        return 'Register Mother';
      default:
        return 'Register Beneficiary';
    }
  }

  String get _secondaryLabel {
    switch (widget.beneficiaryType.toLowerCase()) {
      case 'child':
        return 'Parent Name';
      case 'adolescent':
        return 'School Status';
      case 'mother':
        return 'Pregnancy Status';
      default:
        return 'Details';
    }
  }

  String get _numericLabel {
    if (widget.beneficiaryType.toLowerCase() == 'mother') {
      return 'Number of Children';
    }
    return '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _secondaryController.dispose();
    _numericController.dispose();
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final type = widget.beneficiaryType.toLowerCase();
      switch (type) {
        case 'child':
          await _anganwadiService.registerChild(
            anganwadiId: widget.anganwadiId,
            organizationId: _organizationId,
            name: _nameController.text.trim(),
            childId: _idController.text.trim().isEmpty
                ? null
                : _idController.text.trim(),
            dob: _selectedDob,
            gender: _genderController.text.trim().isEmpty
                ? null
                : _genderController.text.trim(),
            parentName: _secondaryController.text.trim().isEmpty
                ? null
                : _secondaryController.text.trim(),
          );
          break;
        case 'adolescent':
          await _anganwadiService.registerAdolescent(
            anganwadiId: widget.anganwadiId,
            organizationId: _organizationId,
            name: _nameController.text.trim(),
            adolescentId: _idController.text.trim().isEmpty
                ? null
                : _idController.text.trim(),
            dob: _selectedDob,
            gender: _genderController.text.trim().isEmpty
                ? null
                : _genderController.text.trim(),
            schoolStatus: _secondaryController.text.trim().isEmpty
                ? null
                : _secondaryController.text.trim(),
          );
          break;
        case 'mother':
          await _anganwadiService.registerMother(
            anganwadiId: widget.anganwadiId,
            organizationId: _organizationId,
            name: _nameController.text.trim(),
            motherId: _idController.text.trim().isEmpty
                ? null
                : _idController.text.trim(),
            dob: _selectedDob,
            pregnancyStatus: _secondaryController.text.trim().isEmpty
                ? null
                : _secondaryController.text.trim(),
            numberOfChildren: int.tryParse(_numericController.text.trim()),
          );
          break;
        default:
          throw Exception('Unknown beneficiary type');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_title completed successfully.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to register: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: '${widget.beneficiaryType} ID',
                  border: const OutlineInputBorder(),
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
                controller: _secondaryController,
                decoration: InputDecoration(
                  labelText: _secondaryLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_numericLabel.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _numericController,
                  decoration: InputDecoration(
                    labelText: _numericLabel,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _register,
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
