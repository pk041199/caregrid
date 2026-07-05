import 'package:supabase_flutter/supabase_flutter.dart';

class CareGridSupabaseDataset {
  const CareGridSupabaseDataset._();

  static const url = 'https://ugtehiacdmlazqvnvafp.supabase.co';
  static const anonKey = 'sb_publishable_vLxE657DAPWBtnPMhhOu0w_yE5--gN9';

  static const organizationsTable = 'organizations';
  static const organizationUsersTable = 'organization_users';
  static const patientRecordsTable = 'patient_records';
  static const consultRequestsTable = 'consult_requests';
  static const careGridsTable = 'care_grids';
  static const doctorReviewsTable = 'doctor_reviews';

  static Future<void> initialize() {
    return Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
