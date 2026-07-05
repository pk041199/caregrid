import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/beneficiary_models.dart';

class BeneficiaryService {
  final supabase = Supabase.instance.client;

  Future<MasterBeneficiary?> searchBeneficiary({
    required String organizationId,
    String? abhaNumber,
    String? aadhaarLast4,
    String? mobileNumber,
    String? name,
  }) async {
    try {
      if (abhaNumber != null && abhaNumber.isNotEmpty) {
        final result = await supabase
            .from('master_beneficiaries')
            .select()
            .eq('organization_id', organizationId)
            .eq('abha_number', abhaNumber)
            .limit(1);
        if (result.isNotEmpty) {
          return MasterBeneficiary.fromMap(result[0]);
        }
      }

      if (aadhaarLast4 != null && aadhaarLast4.isNotEmpty) {
        final result = await supabase
            .from('master_beneficiaries')
            .select()
            .eq('organization_id', organizationId)
            .eq('aadhaar_last_4', aadhaarLast4)
            .limit(1);
        if (result.isNotEmpty) {
          return MasterBeneficiary.fromMap(result[0]);
        }
      }

      if (mobileNumber != null && mobileNumber.isNotEmpty) {
        final result = await supabase
            .from('master_beneficiaries')
            .select()
            .eq('organization_id', organizationId)
            .eq('mobile_number', mobileNumber)
            .limit(1);
        if (result.isNotEmpty) {
          return MasterBeneficiary.fromMap(result[0]);
        }
      }

      if (name != null && name.isNotEmpty) {
        final result = await supabase
            .from('master_beneficiaries')
            .select()
            .eq('organization_id', organizationId)
            .ilike('name', '%$name%')
            .order('created_at', ascending: false)
            .limit(1);
        if (result.isNotEmpty) {
          return MasterBeneficiary.fromMap(result[0]);
        }
      }

      return null;
    } catch (e) {
      print('Error searching beneficiary: $e');
      return null;
    }
  }

  Future<MasterBeneficiary> updateAbhaDetails({
    required String beneficiaryId,
    required String verificationStatus,
    String? linkedMobile,
    String? address,
  }) async {
    try {
      final response = await supabase
          .from('master_beneficiaries')
          .update({
            'abha_verification_status': verificationStatus,
            'abha_linked_mobile': linkedMobile,
            'abha_address': address,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', beneficiaryId)
          .select()
          .single();

      return MasterBeneficiary.fromMap(response);
    } catch (e) {
      print('Error updating ABHA details: $e');
      rethrow;
    }
  }

  Future<MasterBeneficiary?> getBeneficiaryById({
    required String beneficiaryId,
  }) async {
    try {
      final response = await supabase
          .from('master_beneficiaries')
          .select()
          .eq('id', beneficiaryId)
          .single();

      return MasterBeneficiary.fromMap(response);
    } catch (e) {
      print('Error loading beneficiary by id: $e');
      return null;
    }
  }

  Future<List<DuplicateDetectionResult>> checkDuplicates({
    required String organizationId,
    String? abhaNumber,
    String? aadhaarNumber,
    String? mobileNumber,
    String? name,
    DateTime? dob,
    String? gender,
  }) async {
    try {
      final matches = <DuplicateDetectionResult>[];

      var baseQuery = supabase
          .from('master_beneficiaries')
          .select()
          .eq('organization_id', organizationId);

      // Search for exact ABHA match (highest confidence)
      if (abhaNumber != null && abhaNumber.isNotEmpty) {
        final abhaResults = await baseQuery.eq('abha_number', abhaNumber);
        for (final result in abhaResults) {
          final beneficiary = MasterBeneficiary.fromMap(result);
          matches.add(DuplicateDetectionResult(
            beneficiary: beneficiary,
            confidenceScore: 0.99,
            matchedFields: ['ABHA'],
          ));
        }
      }

      // Search for exact mobile match (high confidence)
      if (mobileNumber != null && mobileNumber.isNotEmpty) {
        final mobileResults =
            await baseQuery.eq('mobile_number', mobileNumber);
        for (final result in mobileResults) {
          if (!matches.any((m) => m.beneficiary.id == result['id'])) {
            final beneficiary = MasterBeneficiary.fromMap(result);
            matches.add(DuplicateDetectionResult(
              beneficiary: beneficiary,
              confidenceScore: 0.95,
              matchedFields: ['Mobile'],
            ));
          }
        }
      }

      // Fuzzy search by name + DOB + gender (medium confidence)
      if ((name != null && name.isNotEmpty) && dob != null && gender != null) {
        final allBeneficiaries = await baseQuery;
        for (final result in allBeneficiaries) {
          if (!matches.any((m) => m.beneficiary.id == result['id'])) {
            final beneficiary = MasterBeneficiary.fromMap(result);
            final nameSimilarity = _calculateNameSimilarity(name, beneficiary.name);
            final dobMatch = beneficiary.dob?.year == dob.year &&
                beneficiary.dob?.month == dob.month &&
                beneficiary.dob?.day == dob.day;
            final genderMatch =
                beneficiary.gender?.toLowerCase() == gender.toLowerCase();

            if (nameSimilarity > 0.7 && dobMatch && genderMatch) {
              final matchedFields = <String>[];
              if (nameSimilarity > 0.9) matchedFields.add('Name');
              if (dobMatch) matchedFields.add('DOB');
              if (genderMatch) matchedFields.add('Gender');

              matches.add(DuplicateDetectionResult(
                beneficiary: beneficiary,
                confidenceScore: (nameSimilarity + (dobMatch ? 0.1 : 0) +
                        (genderMatch ? 0.05 : 0)) /
                    1.15,
                matchedFields: matchedFields,
              ));
            }
          }
        }
      }

      matches.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
      return matches;
    } catch (e) {
      print('Error checking duplicates: $e');
      return [];
    }
  }

  Future<MasterBeneficiary> createMasterBeneficiary({
    required String organizationId,
    required String name,
    DateTime? dob,
    String? gender,
    String? abhaNumber,
    String? abhaAddress,
    String? aadhaarNumber,
    String? mobileNumber,
  }) async {
    try {
      final individualId = _generateIndividualId();

      final aadhaarLast4 = aadhaarNumber != null && aadhaarNumber.length >= 4
          ? aadhaarNumber.substring(aadhaarNumber.length - 4)
          : null;

      final beneficiary = MasterBeneficiary(
        organizationId: organizationId,
        individualId: individualId,
        abhaNumber: abhaNumber,
        abhaAddress: abhaAddress,
        aadhaarNumberEncrypted: null,
        aadhaarLast4: aadhaarLast4,
        mobileNumber: mobileNumber,
        name: name,
        dob: dob,
        gender: gender,
      );

      final response = await supabase
          .from('master_beneficiaries')
          .insert(beneficiary.toMap())
          .select();

      return MasterBeneficiary.fromMap(response[0]);
    } catch (e) {
      print('Error creating master beneficiary: $e');
      rethrow;
    }
  }

  Future<void> linkBeneficiaryToSite({
    required String organizationId,
    required String masterBeneficiaryId,
    required String siteType,
    required String siteId,
    required String siteSpecificId,
  }) async {
    try {
      final link = SiteBeneficiaryLink(
        organizationId: organizationId,
        masterBeneficiaryId: masterBeneficiaryId,
        siteType: siteType,
        siteId: siteId,
        siteSpecificId: siteSpecificId,
      );

      await supabase.from('site_beneficiary_links').insert(link.toMap());
    } catch (e) {
      print('Error linking beneficiary to site: $e');
      rethrow;
    }
  }

  Future<BeneficiaryTimeline?> getBeneficiaryTimeline({
    required String organizationId,
    required String masterBeneficiaryId,
  }) async {
    try {
      final beneficiaryResponse = await supabase
          .from('master_beneficiaries')
          .select()
          .eq('id', masterBeneficiaryId)
          .single();

      final beneficiary = MasterBeneficiary.fromMap(beneficiaryResponse);

      final linksResponse = await supabase
          .from('site_beneficiary_links')
          .select()
          .eq('master_beneficiary_id', masterBeneficiaryId);

      final entries = <TimelineEntry>[];

      for (final link in linksResponse) {
        if (link['site_type'] == 'field') {
          final familyMemberResponse = await supabase
              .from('family_members')
              .select()
              .eq('id', link['site_specific_id']);

          if (familyMemberResponse.isNotEmpty) {
            entries.add(TimelineEntry(
              date: DateTime.parse(familyMemberResponse[0]['created_at']),
              siteType: 'field',
              siteName: 'Field/HDSS',
              formId: 'family_registration',
              formTitle: 'Family Registration',
              data: familyMemberResponse[0],
            ));
          }
        }
      }

      entries.sort((a, b) => b.date.compareTo(a.date));

      return BeneficiaryTimeline(
        beneficiary: beneficiary,
        entries: entries,
      );
    } catch (e) {
      print('Error getting beneficiary timeline: $e');
      return null;
    }
  }

  Future<void> mergeBeneficiaries({
    required String organizationId,
    required String primaryBeneficiaryId,
    required String duplicateBeneficiaryId,
  }) async {
    try {
      final linksToUpdate = await supabase
          .from('site_beneficiary_links')
          .select()
          .eq('master_beneficiary_id', duplicateBeneficiaryId);

      for (final link in linksToUpdate) {
        await supabase
            .from('site_beneficiary_links')
            .update({'master_beneficiary_id': primaryBeneficiaryId})
            .eq('id', link['id']);
      }

      await supabase
          .from('master_beneficiaries')
          .delete()
          .eq('id', duplicateBeneficiaryId);
    } catch (e) {
      print('Error merging beneficiaries: $e');
      rethrow;
    }
  }

  double _calculateNameSimilarity(String name1, String name2) {
    final n1 = name1.toLowerCase();
    final n2 = name2.toLowerCase();

    if (n1 == n2) return 1.0;

    final commonLength = _commonSubstringLength(n1, n2);
    final maxLength = n1.length > n2.length ? n1.length : n2.length;

    return maxLength > 0 ? commonLength / maxLength : 0.0;
  }

  int _commonSubstringLength(String s1, String s2) {
    final longer = s1.length > s2.length ? s1 : s2;
    final shorter = s1.length > s2.length ? s2 : s1;

    int matchCount = 0;
    for (int i = 0; i < shorter.length; i++) {
      if (longer.contains(shorter[i])) {
        matchCount++;
      }
    }
    return matchCount;
  }

  String _generateIndividualId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'IND-$timestamp-$random';
  }
}
