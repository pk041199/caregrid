import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/clinic_service.dart';

class ClinicRegistrationScreen extends StatefulWidget {
  const ClinicRegistrationScreen({
    super.key,
    required this.clinicId,
  });

  final String clinicId;

  @override
  State<ClinicRegistrationScreen> createState() => _ClinicRegistrationScreenState();
}

class _ClinicRegistrationScreenState extends State<ClinicRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _beneficiaryIdController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _visitDate = DateTime.now();
  bool _isSaving = false;
  final ClinicService _clinicService = ClinicService();

  String get _organizationId =>
      AuthService().currentSession?.organizationId ?? 'demo-org';

  @override
  void dispose() {
    _beneficiaryIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickVisitDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _visitDate = picked);
    }
  }

  Future<void> _registerVisit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _clinicService.registerVisit(
        clinicId: widget.clinicId,
        organizationId: _organizationId,
        visitDate: _visitDate,
        masterBeneficiaryId: _beneficiaryIdController.text.trim().isEmpty
            ? null
            : _beneficiaryIdController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clinic visit registered.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to register visit: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinic Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Clinic ID: ${widget.clinicId}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _beneficiaryIdController,
                decoration: const InputDecoration(
                  labelText: 'Master Beneficiary ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText:
                            'Visit Date (${_visitDate.toIso8601String().split('T').first})',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _pickVisitDate,
                    child: const Text('Pick'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Visit Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _registerVisit,
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Visit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
