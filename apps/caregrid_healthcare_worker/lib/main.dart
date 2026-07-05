import 'package:caregrid_supabase_dataset/caregrid_supabase_dataset.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CareGridSupabaseDataset.initialize();
  runApp(const CareGridHealthcareWorkerApp());
}

class CareGridHealthcareWorkerApp extends StatelessWidget {
  const CareGridHealthcareWorkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareGrid Healthcare Worker',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const WorkerHome(),
    );
  }
}

class WorkerHome extends StatelessWidget {
  const WorkerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CareGrid Healthcare Worker')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Healthcare worker app',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text('Use the main worker app at the repo root while this dedicated app shell is being separated.'),
        ],
      ),
    );
  }
}
