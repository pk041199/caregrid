import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/field_service.dart';
import '../app/routes/route_names.dart';

class FamilyRegistrationScreen extends StatefulWidget {
  const FamilyRegistrationScreen({
    super.key,
    required this.gridId,
  });

  final String gridId;

  @override
  State<FamilyRegistrationScreen> createState() => _FamilyRegistrationScreenState();
}

class _FamilyRegistrationScreenState extends State<FamilyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _headNameController = TextEditingController();
  final _addressController = TextEditingController();
  final FieldService _fieldService = FieldService();
  bool _isSaving = false;

  String get _organizationId =>
      AuthService().currentSession?.organizationId ?? 'demo-org';

  @override
  void dispose() {
    _headNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveFamily() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final family = await _fieldService.registerFamily(
        gridId: widget.gridId,
        organizationId: _organizationId,
        familyHeadName: _headNameController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Family registered successfully.')),
      );
      Navigator.pushReplacementNamed(
        context,
        RouteNames.familyMembers,
        arguments: family.id,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save family: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Family')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Grid ID: ${widget.gridId}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _headNameController,
                decoration: const InputDecoration(
                  labelText: 'Family Head Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the family head name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveFamily,
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Family'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
