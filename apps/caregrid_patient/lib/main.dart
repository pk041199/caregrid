import 'package:caregrid_supabase_dataset/caregrid_supabase_dataset.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CareGridSupabaseDataset.initialize();
  runApp(const CareGridPatientApp());
}

class CareGridPatientApp extends StatelessWidget {
  const CareGridPatientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareGrid Patient',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const PatientHome(),
    );
  }
}

class PatientHome extends StatelessWidget {
  const PatientHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CareGrid Patient')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'My health record',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text('See downloaded data, follow-up dates, prescriptions, and doctor advice.'),
          const SizedBox(height: 12),
          const Text('Privacy: patient data stays patient-facing and should only expose the signed-in person record.'),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.video_call_outlined),
            label: const Text('Consult Doctor'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.description_outlined),
            label: const Text('View My Data'),
          ),
        ],
      ),
    );
  }
}
