import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
await Supabase.initialize(
    url: 'https://bbvewbyxyllpaaibdrjh.supabase.co',
    anonKey: 'sb_publishable_baI1hGOIkmnMcvgljp5pRw_T3sglXjs',
  );
  }
}