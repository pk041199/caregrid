import 'package:flutter/material.dart';
import 'app/app_mode.dart';
import 'app/app.dart';
import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  runApp(const CareGridApp(mode: CareGridAppMode.healthcareWorker));
}
