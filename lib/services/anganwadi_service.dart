import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/anganwadi_models.dart';

class AnganwadiService {
  final supabase = Supabase.instance.client;

  Future<Anganwadi> createAnganwadi({
    required String organizationId,
    required String anganwadiName,
    String? anganwadiCode,
    String? village,
    String? supervisor,
    String? workerName,
    String? createdBy,
  }) async {
    try {
      final anganwadi = Anganwadi(
        organizationId: organizationId,
        anganwadiName: anganwadiName,
        anganwadiCode: anganwadiCode,
        village: village,
        supervisor: supervisor,
        workerName: workerName,
        createdBy: createdBy,
      );

      final response = await supabase
          .from('anganwadis')
          .insert(anganwadi.toMap())
          .select();

      return Anganwadi.fromMap(response[0]);
    } catch (e) {
      print('Error creating anganwadi: $e');
      rethrow;
    }
  }

  Future<List<Anganwadi>> getAnganwadis({
    required String organizationId,
  }) async {
    try {
      final response = await supabase
          .from('anganwadis')
          .select()
          .eq('organization_id', organizationId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return response.map((map) => Anganwadi.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching anganwadis: $e');
      return [];
    }
  }

  Future<Anganwadi?> getAnganwadi({required String anganwadiId}) async {
    try {
      final response = await supabase
          .from('anganwadis')
          .select()
          .eq('id', anganwadiId)
          .single();

      return Anganwadi.fromMap(response);
    } catch (e) {
      print('Error fetching anganwadi: $e');
      return null;
    }
  }

  // ============ CHILD BENEFICIARY OPERATIONS ============

  Future<AnganwadiChild> registerChild({
    required String anganwadiId,
    required String organizationId,
    required String name,
    String? childId,
    DateTime? dob,
    String? gender,
    String? parentName,
    String? masterBeneficiaryId,
  }) async {
    try {
      final id = childId ?? _generateBeneficiaryId('CHD');

      final child = AnganwadiChild(
        anganwadiId: anganwadiId,
        organizationId: organizationId,
        childId: id,
        name: name,
        dob: dob,
        gender: gender,
        parentName: parentName,
        masterBeneficiaryId: masterBeneficiaryId,
      );

      final response = await supabase
          .from('anganwadi_children')
          .insert(child.toMap())
          .select();

      return AnganwadiChild.fromMap(response[0]);
    } catch (e) {
      print('Error registering child: $e');
      rethrow;
    }
  }

  Future<List<AnganwadiChild>> getChildren({
    required String anganwadiId,
  }) async {
    try {
      final response = await supabase
          .from('anganwadi_children')
          .select()
          .eq('anganwadi_id', anganwadiId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return response.map((map) => AnganwadiChild.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching children: $e');
      return [];
    }
  }

  // ============ ADOLESCENT BENEFICIARY OPERATIONS ============

  Future<AnganwadiAdolescent> registerAdolescent({
    required String anganwadiId,
    required String organizationId,
    required String name,
    String? adolescentId,
    DateTime? dob,
    String? gender,
    String? schoolStatus,
    String? masterBeneficiaryId,
  }) async {
    try {
      final id = adolescentId ?? _generateBeneficiaryId('ADO');

      final adolescent = AnganwadiAdolescent(
        anganwadiId: anganwadiId,
        organizationId: organizationId,
        adolescentId: id,
        name: name,
        dob: dob,
        gender: gender,
        schoolStatus: schoolStatus,
        masterBeneficiaryId: masterBeneficiaryId,
      );

      final response = await supabase
          .from('anganwadi_adolescents')
          .insert(adolescent.toMap())
          .select();

      return AnganwadiAdolescent.fromMap(response[0]);
    } catch (e) {
      print('Error registering adolescent: $e');
      rethrow;
    }
  }

  Future<List<AnganwadiAdolescent>> getAdolescents({
    required String anganwadiId,
  }) async {
    try {
      final response = await supabase
          .from('anganwadi_adolescents')
          .select()
          .eq('anganwadi_id', anganwadiId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return response.map((map) => AnganwadiAdolescent.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching adolescents: $e');
      return [];
    }
  }

  // ============ MOTHER BENEFICIARY OPERATIONS ============

  Future<AnganwadiMother> registerMother({
    required String anganwadiId,
    required String organizationId,
    required String name,
    String? motherId,
    DateTime? dob,
    String? pregnancyStatus,
    int? numberOfChildren,
    String? masterBeneficiaryId,
  }) async {
    try {
      final id = motherId ?? _generateBeneficiaryId('MTH');

      final mother = AnganwadiMother(
        anganwadiId: anganwadiId,
        organizationId: organizationId,
        motherId: id,
        name: name,
        dob: dob,
        pregnancyStatus: pregnancyStatus,
        numberOfChildren: numberOfChildren,
        masterBeneficiaryId: masterBeneficiaryId,
      );

      final response = await supabase
          .from('anganwadi_mothers')
          .insert(mother.toMap())
          .select();

      return AnganwadiMother.fromMap(response[0]);
    } catch (e) {
      print('Error registering mother: $e');
      rethrow;
    }
  }

  Future<List<AnganwadiMother>> getMothers({
    required String anganwadiId,
  }) async {
    try {
      final response = await supabase
          .from('anganwadi_mothers')
          .select()
          .eq('anganwadi_id', anganwadiId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return response.map((map) => AnganwadiMother.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching mothers: $e');
      return [];
    }
  }

  // ============ AGGREGATE OPERATIONS ============

  Future<Map<String, int>> getBeneficiaryCounts({
    required String anganwadiId,
  }) async {
    try {
      final childCount = await supabase
          .from('anganwadi_children')
          .select('count')
          .eq('anganwadi_id', anganwadiId)
          .eq('status', 'active')
          .count(CountOption.exact);

      final adolescentCount = await supabase
          .from('anganwadi_adolescents')
          .select('count')
          .eq('anganwadi_id', anganwadiId)
          .eq('status', 'active')
          .count(CountOption.exact);

      final motherCount = await supabase
          .from('anganwadi_mothers')
          .select('count')
          .eq('anganwadi_id', anganwadiId)
          .eq('status', 'active')
          .count(CountOption.exact);

      return {
        'children': childCount.count,
        'adolescents': adolescentCount.count,
        'mothers': motherCount.count,
      };
    } catch (e) {
      print('Error getting beneficiary counts: $e');
      return {'children': 0, 'adolescents': 0, 'mothers': 0};
    }
  }

  Future<void> updateChild({
    required String childId,
    double? height,
    double? weight,
    double? muac,
    String? nutritionStatus,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (height != null) updates['height'] = height;
      if (weight != null) updates['weight'] = weight;
      if (muac != null) updates['muac_measurement'] = muac;
      if (nutritionStatus != null) updates['nutrition_status'] = nutritionStatus;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await supabase
          .from('anganwadi_children')
          .update(updates)
          .eq('id', childId);
    } catch (e) {
      print('Error updating child: $e');
      rethrow;
    }
  }

  Future<void> updateAdolescent({
    required String adolescentId,
    double? height,
    double? weight,
    double? bmi,
    String? menstrualStatus,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (height != null) updates['height'] = height;
      if (weight != null) updates['weight'] = weight;
      if (bmi != null) updates['bmi'] = bmi;
      if (menstrualStatus != null) updates['menstrual_status'] = menstrualStatus;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await supabase
          .from('anganwadi_adolescents')
          .update(updates)
          .eq('id', adolescentId);
    } catch (e) {
      print('Error updating adolescent: $e');
      rethrow;
    }
  }

  String _generateBeneficiaryId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return '$prefix-$timestamp-$random';
  }
}
