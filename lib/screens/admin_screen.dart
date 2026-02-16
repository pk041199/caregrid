import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/organization_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final OrganizationService _orgService = OrganizationService();
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();

  bool _isLoading = false;
  bool _isAuthorizing = true;
  bool _isAdmin = false;
  List<dynamic> _organizations = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final role = await _authService.getUserRole();
    if (!mounted) return;

    _isAdmin = role == 'admin';
    _isAuthorizing = false;
    setState(() {});

    if (_isAdmin) {
      await _loadOrganizations();
    }
  }

  Future<void> _loadOrganizations() async {
    final data = await _orgService.getOrganizations();
    if (!mounted) return;

    setState(() {
      _organizations = data;
    });
  }

  Future<void> _createOrganization() async {
    setState(() => _isLoading = true);

    await _orgService.createOrganization(
      name: _nameController.text.trim(),
      type: _typeController.text.trim(),
    );

    _nameController.clear();
    _typeController.clear();

    await _loadOrganizations();

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthorizing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('CareGrid Admin Panel')),
        body: const Center(
          child: Text('Access denied. Admin role required.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CareGrid Admin Panel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Create Organization',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Organization Name'),
            ),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createOrganization,
                    child: const Text('Create'),
                  ),
            const Divider(height: 30),
            const Text(
              'Existing Organizations',
              style: TextStyle(fontSize: 16),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _organizations.length,
                itemBuilder: (context, index) {
                  final org = _organizations[index];
                  return ListTile(
                    title: Text(org['name']),
                    subtitle: Text((org['type'] ?? '').toString()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
