import 'package:uuid/uuid.dart';

class Workplace {
  final String id;
  final String organizationId;
  final String workplaceName;
  final String? workplaceCode;
  final String? industryType;
  final String? location;
  final String status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Workplace({
    String? id,
    required this.organizationId,
    required this.workplaceName,
    this.workplaceCode,
    this.industryType,
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
        'workplace_name': workplaceName,
        'workplace_code': workplaceCode,
        'industry_type': industryType,
        'location': location,
        'status': status,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Workplace.fromMap(Map<String, dynamic> map) => Workplace(
        id: map['id'],
        organizationId: map['organization_id'],
        workplaceName: map['workplace_name'],
        workplaceCode: map['workplace_code'],
        industryType: map['industry_type'],
        location: map['location'],
        status: map['status'] ?? 'active',
        createdBy: map['created_by'],
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );

  Workplace copyWith({
    String? id,
    String? organizationId,
    String? workplaceName,
    String? workplaceCode,
    String? industryType,
    String? location,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Workplace(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        workplaceName: workplaceName ?? this.workplaceName,
        workplaceCode: workplaceCode ?? this.workplaceCode,
        industryType: industryType ?? this.industryType,
        location: location ?? this.location,
        status: status ?? this.status,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class Worker {
  final String id;
  final String workplaceId;
  final String organizationId;
  final String? masterBeneficiaryId;
  final String workerId;
  final String name;
  final DateTime? dob;
  final String? gender;
  final String? occupation;
  final String? jobRole;
  final double? yearsOfExposure;
  final String? workSchedule;
  final String? respiratoryStatus;
  final String? hearingStatus;
  final String? visionStatus;
  final String? bloodPressure;
  final double? bloodGlucose;
  final double? bmi;
  final bool? ppeUsage;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Worker({
    String? id,
    required this.workplaceId,
    required this.organizationId,
    this.masterBeneficiaryId,
    required this.workerId,
    required this.name,
    this.dob,
    this.gender,
    this.occupation,
    this.jobRole,
    this.yearsOfExposure,
    this.workSchedule,
    this.respiratoryStatus,
    this.hearingStatus,
    this.visionStatus,
    this.bloodPressure,
    this.bloodGlucose,
    this.bmi,
    this.ppeUsage,
    this.status = 'active',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'workplace_id': workplaceId,
        'organization_id': organizationId,
        'master_beneficiary_id': masterBeneficiaryId,
        'worker_id': workerId,
        'name': name,
        'dob': dob?.toIso8601String(),
        'gender': gender,
        'occupation': occupation,
        'job_role': jobRole,
        'years_of_exposure': yearsOfExposure,
        'work_schedule': workSchedule,
        'respiratory_status': respiratoryStatus,
        'hearing_status': hearingStatus,
        'vision_status': visionStatus,
        'blood_pressure': bloodPressure,
        'blood_glucose': bloodGlucose,
        'bmi': bmi,
        'ppe_usage': ppeUsage,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Worker.fromMap(Map<String, dynamic> map) => Worker(
        id: map['id'],
        workplaceId: map['workplace_id'],
        organizationId: map['organization_id'],
        masterBeneficiaryId: map['master_beneficiary_id'],
        workerId: map['worker_id'],
        name: map['name'],
        dob: map['dob'] != null ? DateTime.parse(map['dob']) : null,
        gender: map['gender'],
        occupation: map['occupation'],
        jobRole: map['job_role'],
        yearsOfExposure: map['years_of_exposure']?.toDouble(),
        workSchedule: map['work_schedule'],
        respiratoryStatus: map['respiratory_status'],
        hearingStatus: map['hearing_status'],
        visionStatus: map['vision_status'],
        bloodPressure: map['blood_pressure'],
        bloodGlucose: map['blood_glucose']?.toDouble(),
        bmi: map['bmi']?.toDouble(),
        ppeUsage: map['ppe_usage'],
        status: map['status'] ?? 'active',
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );

  Worker copyWith({
    String? id,
    String? workplaceId,
    String? organizationId,
    String? masterBeneficiaryId,
    String? workerId,
    String? name,
    DateTime? dob,
    String? gender,
    String? occupation,
    String? jobRole,
    double? yearsOfExposure,
    String? workSchedule,
    String? respiratoryStatus,
    String? hearingStatus,
    String? visionStatus,
    String? bloodPressure,
    double? bloodGlucose,
    double? bmi,
    bool? ppeUsage,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Worker(
        id: id ?? this.id,
        workplaceId: workplaceId ?? this.workplaceId,
        organizationId: organizationId ?? this.organizationId,
        masterBeneficiaryId: masterBeneficiaryId ?? this.masterBeneficiaryId,
        workerId: workerId ?? this.workerId,
        name: name ?? this.name,
        dob: dob ?? this.dob,
        gender: gender ?? this.gender,
        occupation: occupation ?? this.occupation,
        jobRole: jobRole ?? this.jobRole,
        yearsOfExposure: yearsOfExposure ?? this.yearsOfExposure,
        workSchedule: workSchedule ?? this.workSchedule,
        respiratoryStatus: respiratoryStatus ?? this.respiratoryStatus,
        hearingStatus: hearingStatus ?? this.hearingStatus,
        visionStatus: visionStatus ?? this.visionStatus,
        bloodPressure: bloodPressure ?? this.bloodPressure,
        bloodGlucose: bloodGlucose ?? this.bloodGlucose,
        bmi: bmi ?? this.bmi,
        ppeUsage: ppeUsage ?? this.ppeUsage,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
