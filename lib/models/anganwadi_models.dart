import 'package:uuid/uuid.dart';

class Anganwadi {
  final String id;
  final String organizationId;
  final String anganwadiName;
  final String? anganwadiCode;
  final String? village;
  final String? supervisor;
  final String? workerName;
  final String status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Anganwadi({
    String? id,
    required this.organizationId,
    required this.anganwadiName,
    this.anganwadiCode,
    this.village,
    this.supervisor,
    this.workerName,
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
        'anganwadi_name': anganwadiName,
        'anganwadi_code': anganwadiCode,
        'village': village,
        'supervisor': supervisor,
        'worker_name': workerName,
        'status': status,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Anganwadi.fromMap(Map<String, dynamic> map) => Anganwadi(
        id: map['id'],
        organizationId: map['organization_id'],
        anganwadiName: map['anganwadi_name'],
        anganwadiCode: map['anganwadi_code'],
        village: map['village'],
        supervisor: map['supervisor'],
        workerName: map['worker_name'],
        status: map['status'] ?? 'active',
        createdBy: map['created_by'],
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );

  Anganwadi copyWith({
    String? id,
    String? organizationId,
    String? anganwadiName,
    String? anganwadiCode,
    String? village,
    String? supervisor,
    String? workerName,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Anganwadi(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        anganwadiName: anganwadiName ?? this.anganwadiName,
        anganwadiCode: anganwadiCode ?? this.anganwadiCode,
        village: village ?? this.village,
        supervisor: supervisor ?? this.supervisor,
        workerName: workerName ?? this.workerName,
        status: status ?? this.status,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class AnganwadiChild {
  final String id;
  final String anganwadiId;
  final String organizationId;
  final String? masterBeneficiaryId;
  final String childId;
  final String name;
  final DateTime? dob;
  final String? gender;
  final String? parentName;
  final double? muacMeasurement;
  final double? height;
  final double? weight;
  final String? nutritionStatus;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnganwadiChild({
    String? id,
    required this.anganwadiId,
    required this.organizationId,
    this.masterBeneficiaryId,
    required this.childId,
    required this.name,
    this.dob,
    this.gender,
    this.parentName,
    this.muacMeasurement,
    this.height,
    this.weight,
    this.nutritionStatus,
    this.status = 'active',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'anganwadi_id': anganwadiId,
        'organization_id': organizationId,
        'master_beneficiary_id': masterBeneficiaryId,
        'child_id': childId,
        'name': name,
        'dob': dob?.toIso8601String(),
        'gender': gender,
        'parent_name': parentName,
        'muac_measurement': muacMeasurement,
        'height': height,
        'weight': weight,
        'nutrition_status': nutritionStatus,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory AnganwadiChild.fromMap(Map<String, dynamic> map) => AnganwadiChild(
        id: map['id'],
        anganwadiId: map['anganwadi_id'],
        organizationId: map['organization_id'],
        masterBeneficiaryId: map['master_beneficiary_id'],
        childId: map['child_id'],
        name: map['name'],
        dob: map['dob'] != null ? DateTime.parse(map['dob']) : null,
        gender: map['gender'],
        parentName: map['parent_name'],
        muacMeasurement: map['muac_measurement']?.toDouble(),
        height: map['height']?.toDouble(),
        weight: map['weight']?.toDouble(),
        nutritionStatus: map['nutrition_status'],
        status: map['status'] ?? 'active',
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );

  AnganwadiChild copyWith({
    String? id,
    String? anganwadiId,
    String? organizationId,
    String? masterBeneficiaryId,
    String? childId,
    String? name,
    DateTime? dob,
    String? gender,
    String? parentName,
    double? muacMeasurement,
    double? height,
    double? weight,
    String? nutritionStatus,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AnganwadiChild(
        id: id ?? this.id,
        anganwadiId: anganwadiId ?? this.anganwadiId,
        organizationId: organizationId ?? this.organizationId,
        masterBeneficiaryId: masterBeneficiaryId ?? this.masterBeneficiaryId,
        childId: childId ?? this.childId,
        name: name ?? this.name,
        dob: dob ?? this.dob,
        gender: gender ?? this.gender,
        parentName: parentName ?? this.parentName,
        muacMeasurement: muacMeasurement ?? this.muacMeasurement,
        height: height ?? this.height,
        weight: weight ?? this.weight,
        nutritionStatus: nutritionStatus ?? this.nutritionStatus,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class AnganwadiAdolescent {
  final String id;
  final String anganwadiId;
  final String organizationId;
  final String? masterBeneficiaryId;
  final String adolescentId;
  final String name;
  final DateTime? dob;
  final String? gender;
  final String? schoolStatus;
  final double? height;
  final double? weight;
  final double? bmi;
  final String? menstrualStatus;
  final bool? ifaSupplementation;
  final String? dewormingStatus;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnganwadiAdolescent({
    String? id,
    required this.anganwadiId,
    required this.organizationId,
    this.masterBeneficiaryId,
    required this.adolescentId,
    required this.name,
    this.dob,
    this.gender,
    this.schoolStatus,
    this.height,
    this.weight,
    this.bmi,
    this.menstrualStatus,
    this.ifaSupplementation,
    this.dewormingStatus,
    this.status = 'active',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'anganwadi_id': anganwadiId,
        'organization_id': organizationId,
        'master_beneficiary_id': masterBeneficiaryId,
        'adolescent_id': adolescentId,
        'name': name,
        'dob': dob?.toIso8601String(),
        'gender': gender,
        'school_status': schoolStatus,
        'height': height,
        'weight': weight,
        'bmi': bmi,
        'menstrual_status': menstrualStatus,
        'ifa_supplementation': ifaSupplementation,
        'deworming_status': dewormingStatus,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory AnganwadiAdolescent.fromMap(Map<String, dynamic> map) =>
      AnganwadiAdolescent(
        id: map['id'],
        anganwadiId: map['anganwadi_id'],
        organizationId: map['organization_id'],
        masterBeneficiaryId: map['master_beneficiary_id'],
        adolescentId: map['adolescent_id'],
        name: map['name'],
        dob: map['dob'] != null ? DateTime.parse(map['dob']) : null,
        gender: map['gender'],
        schoolStatus: map['school_status'],
        height: map['height']?.toDouble(),
        weight: map['weight']?.toDouble(),
        bmi: map['bmi']?.toDouble(),
        menstrualStatus: map['menstrual_status'],
        ifaSupplementation: map['ifa_supplementation'],
        dewormingStatus: map['deworming_status'],
        status: map['status'] ?? 'active',
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );

  AnganwadiAdolescent copyWith({
    String? id,
    String? anganwadiId,
    String? organizationId,
    String? masterBeneficiaryId,
    String? adolescentId,
    String? name,
    DateTime? dob,
    String? gender,
    String? schoolStatus,
    double? height,
    double? weight,
    double? bmi,
    String? menstrualStatus,
    bool? ifaSupplementation,
    String? dewormingStatus,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AnganwadiAdolescent(
        id: id ?? this.id,
        anganwadiId: anganwadiId ?? this.anganwadiId,
        organizationId: organizationId ?? this.organizationId,
        masterBeneficiaryId: masterBeneficiaryId ?? this.masterBeneficiaryId,
        adolescentId: adolescentId ?? this.adolescentId,
        name: name ?? this.name,
        dob: dob ?? this.dob,
        gender: gender ?? this.gender,
        schoolStatus: schoolStatus ?? this.schoolStatus,
        height: height ?? this.height,
        weight: weight ?? this.weight,
        bmi: bmi ?? this.bmi,
        menstrualStatus: menstrualStatus ?? this.menstrualStatus,
        ifaSupplementation: ifaSupplementation ?? this.ifaSupplementation,
        dewormingStatus: dewormingStatus ?? this.dewormingStatus,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class AnganwadiMother {
  final String id;
  final String anganwadiId;
  final String organizationId;
  final String? masterBeneficiaryId;
  final String motherId;
  final String name;
  final DateTime? dob;
  final String? pregnancyStatus;
  final int? numberOfChildren;
  final String? contraceptiveUse;
  final String? nutritionStatus;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnganwadiMother({
    String? id,
    required this.anganwadiId,
    required this.organizationId,
    this.masterBeneficiaryId,
    required this.motherId,
    required this.name,
    this.dob,
    this.pregnancyStatus,
    this.numberOfChildren,
    this.contraceptiveUse,
    this.nutritionStatus,
    this.status = 'active',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'anganwadi_id': anganwadiId,
        'organization_id': organizationId,
        'master_beneficiary_id': masterBeneficiaryId,
        'mother_id': motherId,
        'name': name,
        'dob': dob?.toIso8601String(),
        'pregnancy_status': pregnancyStatus,
        'number_of_children': numberOfChildren,
        'contraceptive_use': contraceptiveUse,
        'nutrition_status': nutritionStatus,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory AnganwadiMother.fromMap(Map<String, dynamic> map) => AnganwadiMother(
        id: map['id'],
        anganwadiId: map['anganwadi_id'],
        organizationId: map['organization_id'],
        masterBeneficiaryId: map['master_beneficiary_id'],
        motherId: map['mother_id'],
        name: map['name'],
        dob: map['dob'] != null ? DateTime.parse(map['dob']) : null,
        pregnancyStatus: map['pregnancy_status'],
        numberOfChildren: map['number_of_children'],
        contraceptiveUse: map['contraceptive_use'],
        nutritionStatus: map['nutrition_status'],
        status: map['status'] ?? 'active',
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );

  AnganwadiMother copyWith({
    String? id,
    String? anganwadiId,
    String? organizationId,
    String? masterBeneficiaryId,
    String? motherId,
    String? name,
    DateTime? dob,
    String? pregnancyStatus,
    int? numberOfChildren,
    String? contraceptiveUse,
    String? nutritionStatus,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AnganwadiMother(
        id: id ?? this.id,
        anganwadiId: anganwadiId ?? this.anganwadiId,
        organizationId: organizationId ?? this.organizationId,
        masterBeneficiaryId: masterBeneficiaryId ?? this.masterBeneficiaryId,
        motherId: motherId ?? this.motherId,
        name: name ?? this.name,
        dob: dob ?? this.dob,
        pregnancyStatus: pregnancyStatus ?? this.pregnancyStatus,
        numberOfChildren: numberOfChildren ?? this.numberOfChildren,
        contraceptiveUse: contraceptiveUse ?? this.contraceptiveUse,
        nutritionStatus: nutritionStatus ?? this.nutritionStatus,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
