import 'package:flutter/material.dart';
import '../app/routes/route_names.dart';

class AnganwadiBeneficiaryTypeScreen extends StatelessWidget {
  const AnganwadiBeneficiaryTypeScreen({
    super.key,
    required this.anganwadiId,
    this.initialType,
  });

  final String anganwadiId;
  final String? initialType;

  @override
  Widget build(BuildContext context) {
    final selectedType = initialType?.toLowerCase();
    if (selectedType != null && selectedType.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(
          context,
          RouteNames.anganwadiRegistration,
          arguments: {
            'anganwadiId': anganwadiId,
            'type': selectedType,
          },
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select Beneficiary Type')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.child_care),
              label: const Text('Register Child'),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.anganwadiRegistration,
                  arguments: {
                    'anganwadiId': anganwadiId,
                    'type': 'child',
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text('Register Adolescent'),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.anganwadiRegistration,
                  arguments: {
                    'anganwadiId': anganwadiId,
                    'type': 'adolescent',
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.woman),
              label: const Text('Register Mother'),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.anganwadiRegistration,
                  arguments: {
                    'anganwadiId': anganwadiId,
                    'type': 'mother',
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
