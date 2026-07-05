import 'package:flutter/material.dart';
import '../models/field_models.dart';
import '../services/auth_service.dart';
import '../services/field_service.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({
    super.key,
    required this.familyId,
  });

  final String familyId;

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  final FieldService _fieldService = FieldService();
  final _nameController = TextEditingController();
  final _relationController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late Future<List<FamilyMember>> _membersFuture;
  bool _isSaving = false;
  DateTime? _selectedDate;

  String get _organizationId =>
      AuthService().currentSession?.organizationId ?? 'demo-org';

  @override
  void initState() {
    super.initState();
    _membersFuture = _loadMembers();
  }

  Future<List<FamilyMember>> _loadMembers() async {
    return await _fieldService.getFamilyMembers(familyId: widget.familyId);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _fieldService.addFamilyMember(
        familyId: widget.familyId,
        organizationId: _organizationId,
        fullName: _nameController.text.trim(),
        relation: _relationController.text.trim().isEmpty
            ? null
            : _relationController.text.trim(),
        dob: _selectedDate,
        gender: _genderController.text.trim().isEmpty
            ? null
            : _genderController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family member added successfully')),
      );
      _nameController.clear();
      _relationController.clear();
      _dobController.clear();
      _genderController.clear();
      _selectedDate = null;
      setState(() => _membersFuture = _loadMembers());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save member: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Members')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<FamilyMember>>(
                future: _membersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final members = snapshot.data ?? const [];
                  if (members.isEmpty) {
                    return const Center(child: Text('No members yet.'));
                  }
                  return ListView.separated(
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return Card(
                        child: ListTile(
                          title: Text(member.fullName),
                          subtitle: Text(
                            'Relation: ${member.relation ?? 'Unknown'}\nDOB: ${member.dob != null ? member.dob!.toIso8601String().split('T').first : 'N/A'}',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildAddMemberSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMemberSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Family Member',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the member name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _relationController,
                decoration: const InputDecoration(
                  labelText: 'Relation',
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _addMember,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Member'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
