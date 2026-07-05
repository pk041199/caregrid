import 'package:uuid/uuid.dart';

class MasterBeneficiary {
  final String id;
  final String organizationId;
  final String individualId;
  final String? abhaNumber;
  final String? abhaAddress;
  final String abhaVerificationStatus;
  final String? abhaLinkedMobile;
  final String? aadhaarNumberEncrypted;
  final String? aadhaarLast4;
  final String aadhaarVerificationStatus;
  final String? aadhaarLinkedMobile;
  final String? mobileNumber;
  final String name;
  final DateTime? dob;
  final String? gender;
  final DateTime createdAt;
  final DateTime updatedAt;

  MasterBeneficiary({
    String? id,
    required this.organizationId,
    required this.individualId,
    this.abhaNumber,
    this.abhaAddress,
    this.abhaVerificationStatus = 'pending',
    this.abhaLinkedMobile,
    this.aadhaarNumberEncrypted,
    this.aadhaarLast4,
    this.aadhaarVerificationStatus = 'pending',
    this.aadhaarLinkedMobile,
    this.mobileNumber,
    required this.name,
    this.dob,
    this.gender,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'organization_id': organizationId,
        'individual_id': individualId,
        'abha_number': abhaNumber,
        'abha_address': abhaAddress,
        'abha_verification_status': abhaVerificationStatus,
        'abha_linked_mobile': abhaLinkedMobile,
        'aadhaar_number_encrypted': aadhaarNumberEncrypted,
        'aadhaar_last_4': aadhaarLast4,
        'aadhaar_verification_status': aadhaarVerificationStatus,
        'aadhaar_linked_mobile': aadhaarLinkedMobile,
        'mobile_number': mobileNumber,
        'name': name,
        'dob': dob?.toIso8601String(),
        'gender': gender,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory MasterBeneficiary.fromMap(Map<String, dynamic> map) =>
      MasterBeneficiary(
        id: map['id'],
        organizationId: map['organization_id'],
        individualId: map['individual_id'],
        abhaNumber: map['abha_number'],
        abhaAddress: map['abha_address'],
        abhaVerificationStatus: map['abha_verification_status'] ?? 'pending',
        abhaLinkedMobile: map['abha_linked_mobile'],
        aadhaarNumberEncrypted: map['aadhaar_number_encrypted'],
        aadhaarLast4: map['aadhaar_last_4'],
        aadhaarVerificationStatus:
            map['aadhaar_verification_status'] ?? 'pending',
        aadhaarLinkedMobile: map['aadhaar_linked_mobile'],
        mobileNumber: map['mobile_number'],
        name: map['name'],
        dob: map['dob'] != null ? DateTime.parse(map['dob']) : null,
        gender: map['gender'],
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );

  MasterBeneficiary copyWith({
    String? id,
    String? organizationId,
    String? individualId,
    String? abhaNumber,
    String? abhaAddress,
    String? abhaVerificationStatus,
    String? abhaLinkedMobile,
    String? aadhaarNumberEncrypted,
    String? aadhaarLast4,
    String? aadhaarVerificationStatus,
    String? aadhaarLinkedMobile,
    String? mobileNumber,
    String? name,
    DateTime? dob,
    String? gender,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      MasterBeneficiary(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        individualId: individualId ?? this.individualId,
        abhaNumber: abhaNumber ?? this.abhaNumber,
        abhaAddress: abhaAddress ?? this.abhaAddress,
        abhaVerificationStatus:
            abhaVerificationStatus ?? this.abhaVerificationStatus,
        abhaLinkedMobile: abhaLinkedMobile ?? this.abhaLinkedMobile,
        aadhaarNumberEncrypted:
            aadhaarNumberEncrypted ?? this.aadhaarNumberEncrypted,
        aadhaarLast4: aadhaarLast4 ?? this.aadhaarLast4,
        aadhaarVerificationStatus:
            aadhaarVerificationStatus ?? this.aadhaarVerificationStatus,
        aadhaarLinkedMobile:
            aadhaarLinkedMobile ?? this.aadhaarLinkedMobile,
        mobileNumber: mobileNumber ?? this.mobileNumber,
        name: name ?? this.name,
        dob: dob ?? this.dob,
        gender: gender ?? this.gender,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class SiteBeneficiaryLink {
  final String id;
  final String organizationId;
  final String masterBeneficiaryId;
  final String siteType;
  final String siteId;
  final String siteSpecificId;
  final DateTime createdAt;

  SiteBeneficiaryLink({
    String? id,
    required this.organizationId,
    required this.masterBeneficiaryId,
    required this.siteType,
    required this.siteId,
    required this.siteSpecificId,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'organization_id': organizationId,
        'master_beneficiary_id': masterBeneficiaryId,
        'site_type': siteType,
        'site_id': siteId,
        'site_specific_id': siteSpecificId,
        'created_at': createdAt.toIso8601String(),
      };

  factory SiteBeneficiaryLink.fromMap(Map<String, dynamic> map) =>
      SiteBeneficiaryLink(
        id: map['id'],
        organizationId: map['organization_id'],
        masterBeneficiaryId: map['master_beneficiary_id'],
        siteType: map['site_type'],
        siteId: map['site_id'],
        siteSpecificId: map['site_specific_id'],
        createdAt: DateTime.parse(map['created_at']),
      );

  SiteBeneficiaryLink copyWith({
    String? id,
    String? organizationId,
    String? masterBeneficiaryId,
    String? siteType,
    String? siteId,
    String? siteSpecificId,
    DateTime? createdAt,
  }) =>
      SiteBeneficiaryLink(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        masterBeneficiaryId: masterBeneficiaryId ?? this.masterBeneficiaryId,
        siteType: siteType ?? this.siteType,
        siteId: siteId ?? this.siteId,
        siteSpecificId: siteSpecificId ?? this.siteSpecificId,
        createdAt: createdAt ?? this.createdAt,
      );
}

class BeneficiaryIdentification {
  final String? abhaNumber;
  final String? aadhaarNumber;
  final String? mobileNumber;
  final String? name;
  final DateTime? dob;
  final String? gender;

  BeneficiaryIdentification({
    this.abhaNumber,
    this.aadhaarNumber,
    this.mobileNumber,
    this.name,
    this.dob,
    this.gender,
  });

  Map<String, dynamic> toMap() => {
        'abha_number': abhaNumber,
        'aadhaar_number': aadhaarNumber,
        'mobile_number': mobileNumber,
        'name': name,
        'dob': dob?.toIso8601String(),
        'gender': gender,
      };

  factory BeneficiaryIdentification.fromMap(Map<String, dynamic> map) =>
      BeneficiaryIdentification(
        abhaNumber: map['abha_number'],
        aadhaarNumber: map['aadhaar_number'],
        mobileNumber: map['mobile_number'],
        name: map['name'],
        dob: map['dob'] != null ? DateTime.parse(map['dob']) : null,
        gender: map['gender'],
      );

  bool isEmpty() =>
      abhaNumber == null &&
      aadhaarNumber == null &&
      mobileNumber == null &&
      name == null;

  bool get hasPrimaryIdentifier =>
      abhaNumber != null || aadhaarNumber != null || mobileNumber != null;

  String getIdentifiersSummary() {
    final identifiers = <String>[];
    if (abhaNumber != null) identifiers.add('ABHA: $abhaNumber');
    if (aadhaarNumber != null) identifiers.add('Aadhaar: ${aadhaarNumber!.substring(aadhaarNumber!.length - 4)}');
    if (mobileNumber != null) identifiers.add('Mobile: $mobileNumber');
    return identifiers.join(', ');
  }
}

class DuplicateDetectionResult {
  final MasterBeneficiary beneficiary;
  final double confidenceScore;
  final List<String> matchedFields;

  DuplicateDetectionResult({
    required this.beneficiary,
    required this.confidenceScore,
    required this.matchedFields,
  });

  bool get isHighConfidence => confidenceScore >= 0.9;
  bool get isMediumConfidence => confidenceScore >= 0.7 && confidenceScore < 0.9;
  bool get isLowConfidence => confidenceScore < 0.7;
}

class BeneficiaryTimeline {
  final MasterBeneficiary beneficiary;
  final List<TimelineEntry> entries;

  BeneficiaryTimeline({
    required this.beneficiary,
    required this.entries,
  });

  Map<String, dynamic> toMap() => {
        'beneficiary': beneficiary.toMap(),
        'entries': entries.map((e) => e.toMap()).toList(),
      };
}

class TimelineEntry {
  final DateTime date;
  final String siteType;
  final String siteName;
  final String formId;
  final String formTitle;
  final Map<String, dynamic> data;

  TimelineEntry({
    required this.date,
    required this.siteType,
    required this.siteName,
    required this.formId,
    required this.formTitle,
    required this.data,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'site_type': siteType,
        'site_name': siteName,
        'form_id': formId,
        'form_title': formTitle,
        'data': data,
      };

  factory TimelineEntry.fromMap(Map<String, dynamic> map) => TimelineEntry(
        date: DateTime.parse(map['date']),
        siteType: map['site_type'],
        siteName: map['site_name'],
        formId: map['form_id'],
        formTitle: map['form_title'],
        data: map['data'] ?? {},
      );
}
