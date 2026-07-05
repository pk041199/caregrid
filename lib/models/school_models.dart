import 'package:uuid/uuid.dart';

class School {
  final String id;
  final String organizationId;
  final String schoolName;
  final String? schoolCode;
  final String? managementType;
  final String? location;
  final String status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  School({
    String? id,
    required this.organizationId,
    required this.schoolName,
    this.schoolCode,
    this.managementType,
    this.location,
    this.status = 'active',
    this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'organization_id': organizationId,
        'school_name': schoolName,
        'school_code': schoolCode,
        'management_type': managementType,
        'location': location,
        'status': status,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory School.fromMap(Map<String, dynamic> map) => School(
        id: map['id'],
        organizationId: map['organization_id'],
        schoolName: map['school_name'],
        schoolCode: map['school_code'],
        managementType: map['management_type'],
        location: map['location'],
        status: map['status'] ?? 'active',
        createdBy: map['created_by'],
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );

  School copyWith({
    String? id,
    String? organizationId,
    String? schoolName,
    String? schoolCode,
    String? managementType,
    String? location,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      School(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        schoolName: schoolName ?? this.schoolName,
        schoolCode: schoolCode ?? this.schoolCode,
        managementType: managementType ?? this.managementType,
        location: location ?? this.location,
        status: status ?? this.status,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class Student {
  final String id;
  final String schoolId;
  final String organizationId;
  final String? masterBeneficiaryId;
  final String studentId;
  final String name;
  final DateTime? dob;
  final String? gender;
  final String? className;
  final String? section;
  final double? height;
  final double? weight;
  final double? bmi;
  final String? visionStatus;
  final String? hearingStatus;
  final double? hemoglobin;
  final String? dentalStatus;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    String? id,
    required this.schoolId,
    required this.organizationId,
    this.masterBeneficiaryId,
    required this.studentId,
    required this.name,
    this.dob,
    this.gender,
    this.className,
    this.section,
    this.height,
    this.weight,
    this.bmi,
    this.visionStatus,
    this.hearingStatus,
    this.hemoglobin,
    this.dentalStatus,
    this.status = 'active',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'school_id': schoolId,
        'organization_id': organizationId,
        'master_beneficiary_id': masterBeneficiaryId,
        'student_id': studentId,
        'name': name,
        'dob': dob?.toIso8601String(),
        'gender': gender,
        'class_name': className,
        'section': section,
        'height': height,
        'weight': weight,
        'bmi': bmi,
        'vision_status': visionStatus,
        'hearing_status': hearingStatus,
        'hemoglobin': hemoglobin,
        'dental_status': dentalStatus,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Student.fromMap(Map<String, dynamic> map) => Student(
        id: map['id'],
        schoolId: map['school_id'],
        organizationId: map['organization_id'],
        masterBeneficiaryId: map['master_beneficiary_id'],
        studentId: map['student_id'],
        name: map['name'],
        dob: map['dob'] != null ? DateTime.parse(map['dob']) : null,
        gender: map['gender'],
        className: map['class_name'],
        section: map['section'],
        height: map['height']?.toDouble(),
        weight: map['weight']?.toDouble(),
        bmi: map['bmi']?.toDouble(),
        visionStatus: map['vision_status'],
        hearingStatus: map['hearing_status'],
        hemoglobin: map['hemoglobin']?.toDouble(),
        dentalStatus: map['dental_status'],
        status: map['status'] ?? 'active',
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );

  Student copyWith({
    String? id,
    String? schoolId,
    String? organizationId,
    String? masterBeneficiaryId,
    String? studentId,
    String? name,
    DateTime? dob,
    String? gender,
    String? className,
    String? section,
    double? height,
    double? weight,
    double? bmi,
    String? visionStatus,
    String? hearingStatus,
    double? hemoglobin,
    String? dentalStatus,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Student(
        id: id ?? this.id,
        schoolId: schoolId ?? this.schoolId,
        organizationId: organizationId ?? this.organizationId,
        masterBeneficiaryId: masterBeneficiaryId ?? this.masterBeneficiaryId,
        studentId: studentId ?? this.studentId,
        name: name ?? this.name,
        dob: dob ?? this.dob,
        gender: gender ?? this.gender,
        className: className ?? this.className,
        section: section ?? this.section,
        height: height ?? this.height,
        weight: weight ?? this.weight,
        bmi: bmi ?? this.bmi,
        visionStatus: visionStatus ?? this.visionStatus,
        hearingStatus: hearingStatus ?? this.hearingStatus,
        hemoglobin: hemoglobin ?? this.hemoglobin,
        dentalStatus: dentalStatus ?? this.dentalStatus,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
