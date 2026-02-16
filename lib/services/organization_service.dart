import 'package:supabase_flutter/supabase_flutter.dart';

class OrganizationService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createOrganization({
    required String name,
    required String type,
  }) async {
    await _client.from('organizations').insert({
      'name': name,
      'type': type,
    });
  }

  Future<List<dynamic>> getOrganizations() async {
    return await _client.from('organizations').select();
  }
}
