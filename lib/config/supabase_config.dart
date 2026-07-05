import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://ugtehiacdmlazqvnvafp.supabase.co',
      anonKey: 'sb_publishable_vLxE657DAPWBtnPMhhOu0w_yE5--gN9',
    );
  }
}