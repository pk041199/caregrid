import 'package:uuid/uuid.dart';

class FieldGrid {
  final String id;
  final String organizationId;
  final String gridCode;
  final String? state;
  final String? district;
  final String? mandal;
  final String? village;
  final String status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  FieldGrid({
    String? id,
    required this.organizationId,
    required this.gridCode,
    this.state,
    this.district,
    this.mandal,
    this.village,
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
        'grid_code': gridCode,
        'state': state,
        'district': district,
        'mandal': mandal,
        'village': village,
        'status': status,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory FieldGrid.fromMap(Map<String, dynamic> map) => FieldGrid(
        id: map['id'],
        organizationId: map['organization_id'],
        gridCode: map['grid_code'],
        state: map['state'],
        district: map['district'],
        mandal: map['mandal'],
        village: map['village'],
        status: map['status'] ?? 'active',
        createdBy: map['created_by'],
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );

  FieldGrid copyWith({
    String? id,
    String? organizationId,
    String? gridCode,
    String? state,
    String? district,
    String? mandal,
    String? village,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      FieldGrid(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        gridCode: gridCode ?? this.gridCode,
        state: state ?? this.state,
        district: district ?? this.district,
        mandal: mandal ?? this.mandal,
        village: village ?? this.village,
        status: status ?? this.status,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class Family {
  final String id;
  final String gridId;
  final String organizationId;
  final String familyId;
  final String familyHeadName;
  final String? address;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Family({
    String? id,
    required this.gridId,
    required this.organizationId,
    required this.familyId,
    required this.familyHeadName,
    this.address,
    this.status = 'active',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'grid_id': gridId,
        'organization_id': organizationId,
        'family_id': familyId,
        'family_head_name': familyHeadName,
        'address': address,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Family.fromMap(Map<String, dynamic> map) => Family(
        id: map['id'],
        gridId: map['grid_id'],
        organizationId: map['organization_id'],
        familyId: map['family_id'],
        familyHeadName: map['family_head_name'],
        address: map['address'],
        status: map['status'] ?? 'active',
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );

  Family copyWith({
    String? id,
    String? gridId,
    String? organizationId,
    String? familyId,
    String? familyHeadName,
    String? address,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Family(
        id: id ?? this.id,
        gridId: gridId ?? this.gridId,
        organizationId: organizationId ?? this.organizationId,
        familyId: familyId ?? this.familyId,
        familyHeadName: familyHeadName ?? this.familyHeadName,
        address: address ?? this.address,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class FamilyMember {
  final String id;
  final String familyId;
  final String organizationId;
  final String? masterBeneficiaryId;
  final String fullName;
  final DateTime? dob;
  final String? gender;
  final String? relation;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyMember({
    String? id,
    required this.familyId,
    required this.organizationId,
    this.masterBeneficiaryId,
    required this.fullName,
    this.dob,
    this.gender,
    this.relation,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'family_id': familyId,
        'organization_id': organizationId,
        'master_beneficiary_id': masterBeneficiaryId,
        'full_name': fullName,
        'dob': dob?.toIso8601String(),
        'gender': gender,
        'relation': relation,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory FamilyMember.fromMap(Map<String, dynamic> map) => FamilyMember(
        id: map['id'],
        familyId: map['family_id'],
        organizationId: map['organization_id'],
        masterBeneficiaryId: map['master_beneficiary_id'],
        fullName: map['full_name'],
        dob: map['dob'] != null ? DateTime.parse(map['dob']) : null,
        gender: map['gender'],
        relation: map['relation'],
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );

  FamilyMember copyWith({
    String? id,
    String? familyId,
    String? organizationId,
    String? masterBeneficiaryId,
    String? fullName,
    DateTime? dob,
    String? gender,
    String? relation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      FamilyMember(
        id: id ?? this.id,
        familyId: familyId ?? this.familyId,
        organizationId: organizationId ?? this.organizationId,
        masterBeneficiaryId: masterBeneficiaryId ?? this.masterBeneficiaryId,
        fullName: fullName ?? this.fullName,
        dob: dob ?? this.dob,
        gender: gender ?? this.gender,
        relation: relation ?? this.relation,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
