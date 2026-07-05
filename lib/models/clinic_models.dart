import 'package:uuid/uuid.dart';

class Clinic {
  final String id;
  final String organizationId;
  final String clinicName;
  final String? clinicCode;
  final String? address;
  final String? contactNumber;
  final String status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Clinic({
    String? id,
    required this.organizationId,
    required this.clinicName,
    this.clinicCode,
    this.address,
    this.contactNumber,
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
        'clinic_name': clinicName,
        'clinic_code': clinicCode,
        'address': address,
        'contact_number': contactNumber,
        'status': status,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Clinic.fromMap(Map<String, dynamic> map) => Clinic(
        id: map['id'],
        organizationId: map['organization_id'],
        clinicName: map['clinic_name'],
        clinicCode: map['clinic_code'],
        address: map['address'],
        contactNumber: map['contact_number'],
        status: map['status'] ?? 'active',
        createdBy: map['created_by'],
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );

  Clinic copyWith({
    String? id,
    String? organizationId,
    String? clinicName,
    String? clinicCode,
    String? address,
    String? contactNumber,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Clinic(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        clinicName: clinicName ?? this.clinicName,
        clinicCode: clinicCode ?? this.clinicCode,
        address: address ?? this.address,
        contactNumber: contactNumber ?? this.contactNumber,
        status: status ?? this.status,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class ClinicVisit {
  final String id;
  final String clinicId;
  final String organizationId;
  final String? masterBeneficiaryId;
  final DateTime visitDate;
  final String? formId;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClinicVisit({
    String? id,
    required this.clinicId,
    required this.organizationId,
    this.masterBeneficiaryId,
    required this.visitDate,
    this.formId,
    this.status = 'completed',
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'clinic_id': clinicId,
        'organization_id': organizationId,
        'master_beneficiary_id': masterBeneficiaryId,
        'visit_date': visitDate.toIso8601String(),
        'form_id': formId,
        'status': status,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ClinicVisit.fromMap(Map<String, dynamic> map) => ClinicVisit(
        id: map['id'],
        clinicId: map['clinic_id'],
        organizationId: map['organization_id'],
        masterBeneficiaryId: map['master_beneficiary_id'],
        visitDate: DateTime.parse(map['visit_date']),
        formId: map['form_id'],
        status: map['status'] ?? 'completed',
        notes: map['notes'],
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );

  ClinicVisit copyWith({
    String? id,
    String? clinicId,
    String? organizationId,
    String? masterBeneficiaryId,
    DateTime? visitDate,
    String? formId,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ClinicVisit(
        id: id ?? this.id,
        clinicId: clinicId ?? this.clinicId,
        organizationId: organizationId ?? this.organizationId,
        masterBeneficiaryId: masterBeneficiaryId ?? this.masterBeneficiaryId,
        visitDate: visitDate ?? this.visitDate,
        formId: formId ?? this.formId,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
