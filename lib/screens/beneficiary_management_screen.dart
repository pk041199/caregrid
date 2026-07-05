import 'package:flutter/material.dart';
import '../models/beneficiary_models.dart';
import '../services/auth_service.dart';
import '../services/beneficiary_service.dart';

class BeneficiaryManagementScreen extends StatefulWidget {
  const BeneficiaryManagementScreen({super.key, required this.mode});

  final String mode;

  @override
  State<BeneficiaryManagementScreen> createState() => _BeneficiaryManagementScreenState();
}

class _BeneficiaryManagementScreenState extends State<BeneficiaryManagementScreen> {
  final _beneficiaryService = BeneficiaryService();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _abhaController = TextEditingController();
  final _abhaAddressController = TextEditingController();
  final _abhaLinkedMobileController = TextEditingController();
  final _aadhaarController = TextEditingController();
  bool _isBusy = false;
  MasterBeneficiary? _selectedBeneficiary;
  List<DuplicateDetectionResult> _duplicates = [];
  List<TimelineEntry> _timelineEntries = [];

  String get _organizationId =>
      AuthService().currentSession?.organizationId ?? 'demo-org';

  String get _title {
    switch (widget.mode) {
      case 'identification':
        return 'Beneficiary Identification';
      case 'timeline':
        return 'Beneficiary Timeline';
      case 'merge':
        return 'Beneficiary Merge';
      case 'duplicates':
        return 'Duplicate Detection';
      default:
        return 'Beneficiary Management';
    }
  }

  String get _subtitle {
    switch (widget.mode) {
      case 'identification':
        return 'Search beneficiaries by ABHA, mobile, Aadhaar, or name.';
      case 'timeline':
        return 'Load the beneficiary history and follow-up timeline.';
      case 'merge':
        return 'Merge duplicate beneficiary records safely.';
      case 'duplicates':
        return 'Review possible duplicate records before merge.';
      default:
        return 'Manage beneficiary data across sites.';
    }
  }

  Future<void> _search() async {
    setState(() {
      _isBusy = true;
      _duplicates = [];
      _timelineEntries = [];
    });

    try {
      final beneficiary = await _beneficiaryService.searchBeneficiary(
        organizationId: _organizationId,
        name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        mobileNumber: _mobileController.text.trim().isNotEmpty ? _mobileController.text.trim() : null,
        abhaNumber: _abhaController.text.trim().isNotEmpty ? _abhaController.text.trim() : null,
        aadhaarLast4: _aadhaarController.text.trim().isNotEmpty ? _aadhaarController.text.trim() : null,
      );

      setState(() {
        _selectedBeneficiary = beneficiary;
      });

      if (widget.mode == 'timeline' && beneficiary != null) {
        await _loadTimeline(beneficiary.id);
      }
    } finally {
      setState(() => _isBusy = false);
    }
  }

  Future<void> _createBeneficiary() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name to create a beneficiary.')),
      );
      return;
    }

    setState(() => _isBusy = true);

    try {
      final created = await _beneficiaryService.createMasterBeneficiary(
        organizationId: _organizationId,
        name: name,
        dob: null,
        gender: null,
        abhaNumber: _abhaController.text.trim().isNotEmpty ? _abhaController.text.trim() : null,
        abhaAddress: _abhaAddressController.text.trim().isNotEmpty
            ? _abhaAddressController.text.trim()
            : null,
        aadhaarNumber: _aadhaarController.text.trim().isNotEmpty
            ? _aadhaarController.text.trim()
            : null,
        mobileNumber: _mobileController.text.trim().isNotEmpty
            ? _mobileController.text.trim()
            : null,
      );

      setState(() {
        _selectedBeneficiary = created;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beneficiary created successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create beneficiary: $e')),
      );
    } finally {
      setState(() => _isBusy = false);
    }
  }

  Future<void> _updateAbhaStatus(String status) async {
    if (_selectedBeneficiary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search or select a beneficiary first.')),
      );
      return;
    }

    setState(() => _isBusy = true);
    try {
      final updated = await _beneficiaryService.updateAbhaDetails(
        beneficiaryId: _selectedBeneficiary!.id,
        verificationStatus: status,
        linkedMobile: _abhaLinkedMobileController.text.trim().isNotEmpty
            ? _abhaLinkedMobileController.text.trim()
            : null,
        address: _abhaAddressController.text.trim().isNotEmpty
            ? _abhaAddressController.text.trim()
            : null,
      );

      setState(() {
        _selectedBeneficiary = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ABHA status updated to "$status".')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ABHA update failed: $e')),
      );
    } finally {
      setState(() => _isBusy = false);
    }
  }

  Future<void> _detectDuplicates() async {
    setState(() {
      _isBusy = true;
      _timelineEntries = [];
      _selectedBeneficiary = null;
    });

    try {
      final duplicates = await _beneficiaryService.checkDuplicates(
        organizationId: _organizationId,
        name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        mobileNumber: _mobileController.text.trim().isNotEmpty ? _mobileController.text.trim() : null,
        abhaNumber: _abhaController.text.trim().isNotEmpty ? _abhaController.text.trim() : null,
        aadhaarNumber: _aadhaarController.text.trim().isNotEmpty ? _aadhaarController.text.trim() : null,
      );
      setState(() => _duplicates = duplicates);
    } finally {
      setState(() => _isBusy = false);
    }
  }

  Future<void> _loadTimeline(String beneficiaryId) async {
    final timeline = await _beneficiaryService.getBeneficiaryTimeline(
      organizationId: _organizationId,
      masterBeneficiaryId: beneficiaryId,
    );
    setState(() {
      _timelineEntries = timeline?.entries ?? [];
    });
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: _isBusy ? null : _search,
          icon: const Icon(Icons.search),
          label: const Text('Search'),
        ),
        if (widget.mode == 'duplicates')
          ElevatedButton.icon(
            onPressed: _isBusy ? null : _detectDuplicates,
            icon: const Icon(Icons.fact_check),
            label: const Text('Check Duplicates'),
          ),
        if (widget.mode == 'identification')
          ElevatedButton.icon(
            onPressed: _isBusy ? null : _createBeneficiary,
            icon: const Icon(Icons.add),
            label: const Text('Create Beneficiary'),
          ),
        if (widget.mode == 'timeline' && _selectedBeneficiary != null)
          ElevatedButton.icon(
            onPressed: _isBusy ? null : () => _loadTimeline(_selectedBeneficiary!.id),
            icon: const Icon(Icons.timeline),
            label: const Text('Reload Timeline'),
          ),
      ],
    );
  }

  Widget _buildBeneficiaryCard() {
    final beneficiary = _selectedBeneficiary;
    if (beneficiary == null) {
      return const Card(
        child: ListTile(
          title: Text('No beneficiary selected'),
          subtitle: Text('Search by ABHA, mobile, Aadhaar, or name.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(beneficiary.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('ID: ${beneficiary.individualId}'),
            const SizedBox(height: 4),
            Text('ABHA: ${beneficiary.abhaNumber ?? 'Not provided'}'),
            const SizedBox(height: 4),
            Text('ABHA status: ${beneficiary.abhaVerificationStatus}'),
            const SizedBox(height: 4),
            Text('Linked mobile: ${beneficiary.abhaLinkedMobile ?? 'None'}'),
            const SizedBox(height: 4),
            Text('Mobile: ${beneficiary.mobileNumber ?? 'None'}'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isBusy ? null : () => _updateAbhaStatus('verified'),
                  child: const Text('Mark Verified'),
                ),
                ElevatedButton(
                  onPressed: _isBusy ? null : () => _updateAbhaStatus('pending'),
                  child: const Text('Mark Pending'),
                ),
                ElevatedButton(
                  onPressed: _isBusy ? null : () => _updateAbhaStatus('rejected'),
                  child: const Text('Mark Rejected'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    if (widget.mode != 'timeline') return const SizedBox.shrink();

    if (_selectedBeneficiary == null) {
      return const SizedBox.shrink();
    }

    if (_timelineEntries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No timeline entries found for this beneficiary.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text('Timeline entries', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._timelineEntries.map(
          (entry) => Card(
            child: ListTile(
              title: Text(entry.formTitle),
              subtitle: Text('${entry.siteName} • ${entry.date.toIso8601String().split('T').first}'),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDuplicateSection() {
    if (widget.mode != 'duplicates') return const SizedBox.shrink();

    if (_duplicates.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No duplicate candidates identified yet.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text('Duplicate candidates', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._duplicates.map((duplicate) => Card(
              child: ListTile(
                title: Text(duplicate.beneficiary.name),
                subtitle: Text('Confidence: ${(duplicate.confidenceScore * 100).toStringAsFixed(0)}% • ${duplicate.matchedFields.join(', ')}'),
                trailing: duplicate.isHighConfidence
                    ? const Icon(Icons.verified, color: Colors.green)
                    : const Icon(Icons.warning_amber, color: Colors.orange),
              ),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(_subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _mobileController,
                    decoration: const InputDecoration(labelText: 'Mobile Number'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _abhaController,
                    decoration: const InputDecoration(labelText: 'ABHA Number'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _abhaAddressController,
                    decoration: const InputDecoration(labelText: 'ABHA Address'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _abhaLinkedMobileController,
                    decoration: const InputDecoration(labelText: 'ABHA Linked Mobile'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _aadhaarController,
                    decoration: const InputDecoration(labelText: 'Aadhaar Last 4'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_isBusy) const Center(child: CircularProgressIndicator()),
          if (!_isBusy) _buildBeneficiaryCard(),
          _buildTimelineSection(),
          _buildDuplicateSection(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _abhaController.dispose();
    _abhaAddressController.dispose();
    _abhaLinkedMobileController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }
}
