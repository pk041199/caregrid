import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/school_models.dart';

class SchoolService {
  final supabase = Supabase.instance.client;

  Future<School> createSchool({
    required String organizationId,
    required String schoolName,
    String? schoolCode,
    String? managementType,
    String? location,
    String? createdBy,
  }) async {
    try {
      final school = School(
        organizationId: organizationId,
        schoolName: schoolName,
        schoolCode: schoolCode,
        managementType: managementType,
        location: location,
        createdBy: createdBy,
      );

      final response =
          await supabase.from('schools').insert(school.toMap()).select();

      return School.fromMap(response[0]);
    } catch (e) {
      print('Error creating school: $e');
      rethrow;
    }
  }

  Future<List<School>> getSchools({
    required String organizationId,
  }) async {
    try {
      final response = await supabase
          .from('schools')
          .select()
          .eq('organization_id', organizationId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return response.map((map) => School.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching schools: $e');
      return [];
    }
  }

  Future<School?> getSchool({required String schoolId}) async {
    try {
      final response = await supabase
          .from('schools')
          .select()
          .eq('id', schoolId)
          .single();

      return School.fromMap(response);
    } catch (e) {
      print('Error fetching school: $e');
      return null;
    }
  }

  Future<Student> registerStudent({
    required String schoolId,
    required String organizationId,
    required String name,
    String? studentId,
    DateTime? dob,
    String? gender,
    String? className,
    String? section,
    String? masterBeneficiaryId,
  }) async {
    try {
      final id = studentId ?? _generateStudentId();

      final student = Student(
        schoolId: schoolId,
        organizationId: organizationId,
        studentId: id,
        name: name,
        dob: dob,
        gender: gender,
        className: className,
        section: section,
        masterBeneficiaryId: masterBeneficiaryId,
      );

      final response = await supabase
          .from('students')
          .insert(student.toMap())
          .select();

      return Student.fromMap(response[0]);
    } catch (e) {
      print('Error registering student: $e');
      rethrow;
    }
  }

  Future<List<Student>> getStudents({
    required String schoolId,
  }) async {
    try {
      final response = await supabase
          .from('students')
          .select()
          .eq('school_id', schoolId)
          .eq('status', 'active')
          .order('class_name', ascending: true)
          .order('name', ascending: true);

      return response.map((map) => Student.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }

  Future<List<Student>> getStudentsByClass({
    required String schoolId,
    required String className,
  }) async {
    try {
      final response = await supabase
          .from('students')
          .select()
          .eq('school_id', schoolId)
          .eq('class_name', className)
          .eq('status', 'active')
          .order('section', ascending: true)
          .order('name', ascending: true);

      return response.map((map) => Student.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching students by class: $e');
      return [];
    }
  }

  Future<Student?> getStudent({required String studentId}) async {
    try {
      final response = await supabase
          .from('students')
          .select()
          .eq('id', studentId)
          .single();

      return Student.fromMap(response);
    } catch (e) {
      print('Error fetching student: $e');
      return null;
    }
  }

  Future<int> getStudentCount({
    required String schoolId,
  }) async {
    try {
      final response = await supabase
          .from('students')
          .select('count')
          .eq('school_id', schoolId)
          .eq('status', 'active')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      print('Error getting student count: $e');
      return 0;
    }
  }

  Future<Map<String, int>> getScreeningStats({
    required String schoolId,
  }) async {
    try {
      final response = await supabase
          .from('students')
          .select()
          .eq('school_id', schoolId)
          .eq('status', 'active');

      int withHeight = 0,
          withWeight = 0,
          withBMI = 0,
          withVision = 0,
          withHearing = 0;

      for (final student in response) {
        final s = Student.fromMap(student);
        if (s.height != null) withHeight++;
        if (s.weight != null) withWeight++;
        if (s.bmi != null) withBMI++;
        if (s.visionStatus != null) withVision++;
        if (s.hearingStatus != null) withHearing++;
      }

      return {
        'total': response.length,
        'with_height': withHeight,
        'with_weight': withWeight,
        'with_bmi': withBMI,
        'with_vision': withVision,
        'with_hearing': withHearing,
      };
    } catch (e) {
      print('Error getting screening stats: $e');
      return {};
    }
  }

  Future<void> updateStudentScreening({
    required String studentId,
    double? height,
    double? weight,
    double? bmi,
    String? visionStatus,
    String? hearingStatus,
    double? hemoglobin,
    String? dentalStatus,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (height != null) updates['height'] = height;
      if (weight != null) updates['weight'] = weight;
      if (bmi != null) updates['bmi'] = bmi;
      if (visionStatus != null) updates['vision_status'] = visionStatus;
      if (hearingStatus != null) updates['hearing_status'] = hearingStatus;
      if (hemoglobin != null) updates['hemoglobin'] = hemoglobin;
      if (dentalStatus != null) updates['dental_status'] = dentalStatus;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await supabase.from('students').update(updates).eq('id', studentId);
    } catch (e) {
      print('Error updating student screening: $e');
      rethrow;
    }
  }

  Future<void> updateSchool({
    required String schoolId,
    String? schoolName,
    String? managementType,
    String? location,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (schoolName != null) updates['school_name'] = schoolName;
      if (managementType != null) updates['management_type'] = managementType;
      if (location != null) updates['location'] = location;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await supabase.from('schools').update(updates).eq('id', schoolId);
    } catch (e) {
      print('Error updating school: $e');
      rethrow;
    }
  }

  String _generateStudentId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'STU-$timestamp-$random';
  }
}
