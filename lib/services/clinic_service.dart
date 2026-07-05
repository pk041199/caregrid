import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clinic_models.dart';

class ClinicService {
  final supabase = Supabase.instance.client;

  Future<Clinic> createClinic({
    required String organizationId,
    required String clinicName,
    String? clinicCode,
    String? address,
    String? contactNumber,
    String? createdBy,
  }) async {
    try {
      final clinic = Clinic(
        organizationId: organizationId,
        clinicName: clinicName,
        clinicCode: clinicCode,
        address: address,
        contactNumber: contactNumber,
        createdBy: createdBy,
      );

      final response =
          await supabase.from('clinics').insert(clinic.toMap()).select();

      return Clinic.fromMap(response[0]);
    } catch (e) {
      print('Error creating clinic: $e');
      rethrow;
    }
  }

  Future<List<Clinic>> getClinics({
    required String organizationId,
  }) async {
    try {
      final response = await supabase
          .from('clinics')
          .select()
          .eq('organization_id', organizationId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return response.map((map) => Clinic.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching clinics: $e');
      return [];
    }
  }

  Future<Clinic?> getClinic({required String clinicId}) async {
    try {
      final response = await supabase
          .from('clinics')
          .select()
          .eq('id', clinicId)
          .single();

      return Clinic.fromMap(response);
    } catch (e) {
      print('Error fetching clinic: $e');
      return null;
    }
  }

  Future<ClinicVisit> registerVisit({
    required String clinicId,
    required String organizationId,
    String? masterBeneficiaryId,
    required DateTime visitDate,
    String? formId,
    String? notes,
  }) async {
    try {
      final visit = ClinicVisit(
        clinicId: clinicId,
        organizationId: organizationId,
        masterBeneficiaryId: masterBeneficiaryId,
        visitDate: visitDate,
        formId: formId,
        notes: notes,
      );

      final response = await supabase
          .from('clinic_visits')
          .insert(visit.toMap())
          .select();

      return ClinicVisit.fromMap(response[0]);
    } catch (e) {
      print('Error registering visit: $e');
      rethrow;
    }
  }

  Future<List<ClinicVisit>> getClinicVisits({
    required String clinicId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query =
          supabase.from('clinic_visits').select().eq('clinic_id', clinicId);

      if (fromDate != null) {
        query =
            query.gte('visit_date', fromDate.toIso8601String().split('T')[0]);
      }
      if (toDate != null) {
        query = query.lte('visit_date', toDate.toIso8601String().split('T')[0]);
      }

      final response =
          await query.order('visit_date', ascending: false);

      return response.map((map) => ClinicVisit.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching clinic visits: $e');
      return [];
    }
  }

  Future<List<ClinicVisit>> getBeneficiaryVisits({
    required String masterBeneficiaryId,
  }) async {
    try {
      final response = await supabase
          .from('clinic_visits')
          .select()
          .eq('master_beneficiary_id', masterBeneficiaryId)
          .order('visit_date', ascending: false);

      return response.map((map) => ClinicVisit.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching beneficiary visits: $e');
      return [];
    }
  }

  Future<int> getTodayVisitCount({
    required String clinicId,
  }) async {
    try {
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];

      final response = await supabase
          .from('clinic_visits')
          .select('count')
          .eq('clinic_id', clinicId)
          .eq('visit_date', todayStr)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      print('Error getting today visit count: $e');
      return 0;
    }
  }

  Future<int> getMonthlyVisitCount({
    required String clinicId,
  }) async {
    try {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);

      final response = await supabase
          .from('clinic_visits')
          .select('count')
          .eq('clinic_id', clinicId)
          .gte('visit_date', firstDay.toIso8601String().split('T')[0])
          .lte('visit_date', lastDay.toIso8601String().split('T')[0])
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      print('Error getting monthly visit count: $e');
      return 0;
    }
  }

  Future<void> updateClinic({
    required String clinicId,
    String? clinicName,
    String? clinicCode,
    String? address,
    String? contactNumber,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (clinicName != null) updates['clinic_name'] = clinicName;
      if (clinicCode != null) updates['clinic_code'] = clinicCode;
      if (address != null) updates['address'] = address;
      if (contactNumber != null) updates['contact_number'] = contactNumber;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await supabase.from('clinics').update(updates).eq('id', clinicId);
    } catch (e) {
      print('Error updating clinic: $e');
      rethrow;
    }
  }

  Future<void> closeClinic({required String clinicId}) async {
    try {
      await supabase
          .from('clinics')
          .update({
            'status': 'inactive',
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', clinicId);
    } catch (e) {
      print('Error closing clinic: $e');
      rethrow;
    }
  }
}
