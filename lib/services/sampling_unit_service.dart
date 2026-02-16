import 'package:supabase_flutter/supabase_flutter.dart';

class SamplingUnitOption {
  SamplingUnitOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory SamplingUnitOption.fromMap(Map<String, dynamic> map) {
    final rawName = map['name'] ?? map['unit_name'] ?? map['title'] ?? '';
    return SamplingUnitOption(
      id: (map['id'] ?? '').toString(),
      name: rawName.toString(),
    );
  }
}

class SamplingUnitService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<SamplingUnitOption>> getSamplingUnits({
    String? organizationId,
  }) async {
    final query = _client.from('sampling_units').select();
    final response = organizationId == null || organizationId.isEmpty
        ? await query
        : await query.eq('organization_id', organizationId);

    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
    final units = rows
        .map(SamplingUnitOption.fromMap)
        .where((unit) => unit.id.isNotEmpty && unit.name.isNotEmpty)
        .toList();
    units.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return units;
  }
}
