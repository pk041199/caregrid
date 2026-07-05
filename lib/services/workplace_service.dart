import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workplace_models.dart';

class WorkplaceService {
  final supabase = Supabase.instance.client;

  Future<Workplace> createWorkplace({
    required String organizationId,
    required String workplaceName,
    String? workplaceCode,
    String? industryType,
    String? location,
    String? createdBy,
  }) async {
    try {
      final workplace = Workplace(
        organizationId: organizationId,
        workplaceName: workplaceName,
        workplaceCode: workplaceCode,
        industryType: industryType,
        location: location,
        createdBy: createdBy,
      );

      final response = await supabase
          .from('workplaces')
          .insert(workplace.toMap())
          .select();

      return Workplace.fromMap(response[0]);
    } catch (e) {
      print('Error creating workplace: $e');
      rethrow;
    }
  }

  Future<List<Workplace>> getWorkplaces({
    required String organizationId,
  }) async {
    try {
      final response = await supabase
          .from('workplaces')
          .select()
          .eq('organization_id', organizationId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return response.map((map) => Workplace.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching workplaces: $e');
      return [];
    }
  }

  Future<Workplace?> getWorkplace({required String workplaceId}) async {
    try {
      final response = await supabase
          .from('workplaces')
          .select()
          .eq('id', workplaceId)
          .single();

      return Workplace.fromMap(response);
    } catch (e) {
      print('Error fetching workplace: $e');
      return null;
    }
  }

  Future<Worker> registerWorker({
    required String workplaceId,
    required String organizationId,
    required String name,
    String? workerId,
    DateTime? dob,
    String? gender,
    String? occupation,
    String? jobRole,
    double? yearsOfExposure,
    String? masterBeneficiaryId,
  }) async {
    try {
      final id = workerId ?? _generateWorkerId();

      final worker = Worker(
        workplaceId: workplaceId,
        organizationId: organizationId,
        workerId: id,
        name: name,
        dob: dob,
        gender: gender,
        occupation: occupation,
        jobRole: jobRole,
        yearsOfExposure: yearsOfExposure,
        masterBeneficiaryId: masterBeneficiaryId,
      );

      final response = await supabase
          .from('workers')
          .insert(worker.toMap())
          .select();

      return Worker.fromMap(response[0]);
    } catch (e) {
      print('Error registering worker: $e');
      rethrow;
    }
  }

  Future<List<Worker>> getWorkers({
    required String workplaceId,
  }) async {
    try {
      final response = await supabase
          .from('workers')
          .select()
          .eq('workplace_id', workplaceId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return response.map((map) => Worker.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching workers: $e');
      return [];
    }
  }

  Future<List<Worker>> getWorkersByOccupation({
    required String workplaceId,
    required String occupation,
  }) async {
    try {
      final response = await supabase
          .from('workers')
          .select()
          .eq('workplace_id', workplaceId)
          .eq('occupation', occupation)
          .eq('status', 'active')
          .order('name', ascending: true);

      return response.map((map) => Worker.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching workers by occupation: $e');
      return [];
    }
  }

  Future<Worker?> getWorker({required String workerId}) async {
    try {
      final response = await supabase
          .from('workers')
          .select()
          .eq('id', workerId)
          .single();

      return Worker.fromMap(response);
    } catch (e) {
      print('Error fetching worker: $e');
      return null;
    }
  }

  Future<int> getWorkerCount({
    required String workplaceId,
  }) async {
    try {
      final response = await supabase
          .from('workers')
          .select('count')
          .eq('workplace_id', workplaceId)
          .eq('status', 'active')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      print('Error getting worker count: $e');
      return 0;
    }
  }

  Future<Map<String, int>> getScreeningStats({
    required String workplaceId,
  }) async {
    try {
      final response = await supabase
          .from('workers')
          .select()
          .eq('workplace_id', workplaceId)
          .eq('status', 'active');

      int withBloodPressure = 0,
          withGlucose = 0,
          withBMI = 0,
          withRespiratory = 0,
          withHearing = 0;

      for (final worker in response) {
        final w = Worker.fromMap(worker);
        if (w.bloodPressure != null) withBloodPressure++;
        if (w.bloodGlucose != null) withGlucose++;
        if (w.bmi != null) withBMI++;
        if (w.respiratoryStatus != null) withRespiratory++;
        if (w.hearingStatus != null) withHearing++;
      }

      return {
        'total': response.length,
        'with_blood_pressure': withBloodPressure,
        'with_glucose': withGlucose,
        'with_bmi': withBMI,
        'with_respiratory': withRespiratory,
        'with_hearing': withHearing,
      };
    } catch (e) {
      print('Error getting screening stats: $e');
      return {};
    }
  }

  Future<void> updateWorkerScreening({
    required String workerId,
    String? respiratoryStatus,
    String? hearingStatus,
    String? visionStatus,
    String? bloodPressure,
    double? bloodGlucose,
    double? bmi,
    bool? ppeUsage,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (respiratoryStatus != null) updates['respiratory_status'] = respiratoryStatus;
      if (hearingStatus != null) updates['hearing_status'] = hearingStatus;
      if (visionStatus != null) updates['vision_status'] = visionStatus;
      if (bloodPressure != null) updates['blood_pressure'] = bloodPressure;
      if (bloodGlucose != null) updates['blood_glucose'] = bloodGlucose;
      if (bmi != null) updates['bmi'] = bmi;
      if (ppeUsage != null) updates['ppe_usage'] = ppeUsage;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await supabase.from('workers').update(updates).eq('id', workerId);
    } catch (e) {
      print('Error updating worker screening: $e');
      rethrow;
    }
  }

  Future<void> updateWorkplace({
    required String workplaceId,
    String? workplaceName,
    String? industryType,
    String? location,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (workplaceName != null) updates['workplace_name'] = workplaceName;
      if (industryType != null) updates['industry_type'] = industryType;
      if (location != null) updates['location'] = location;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await supabase.from('workplaces').update(updates).eq('id', workplaceId);
    } catch (e) {
      print('Error updating workplace: $e');
      rethrow;
    }
  }

  String _generateWorkerId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'WRK-$timestamp-$random';
  }
}
