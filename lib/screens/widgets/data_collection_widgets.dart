import 'package:flutter/material.dart';

class GridContextCard extends StatelessWidget {
  const GridContextCard({
    super.key,
    required this.samplingUnit,
    required this.setupData,
  });

  final String samplingUnit;
  final Map<String, String> setupData;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sampling Unit: $samplingUnit'),
            Text('State: ${setupData['state'] ?? '-'}'),
            Text('District: ${setupData['district'] ?? '-'}'),
            Text('Taluk/Mandal: ${setupData['taluk'] ?? '-'}'),
            Text('Area Code: ${setupData['areaCode'] ?? '-'}'),
          ],
        ),
      ),
    );
  }
}

class FamilyListHeader extends StatelessWidget {
  const FamilyListHeader({
    super.key,
    required this.familyCount,
    required this.onAddEntry,
  });

  final int familyCount;
  final VoidCallback onAddEntry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Saved Family Entries: $familyCount',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: onAddEntry,
          icon: const Icon(Icons.add),
          label: const Text('Add Entry'),
        ),
      ],
    );
  }
}
