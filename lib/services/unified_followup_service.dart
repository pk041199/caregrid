import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/followup_models.dart';

class UnifiedFollowUpService {
  final supabase = Supabase.instance.client;

  Future<UnifiedFollowUp> createFollowUp({
    required String organizationId,
    required String masterBeneficiaryId,
    required String siteType,
    required String siteId,
    required DateTime followUpDate,
    String? formId,
    String? assignedTo,
    String? assignedToName,
    String? notes,
  }) async {
    try {
      final followUp = UnifiedFollowUp(
        organizationId: organizationId,
        masterBeneficiaryId: masterBeneficiaryId,
        siteType: siteType,
        siteId: siteId,
        formId: formId,
        followUpDate: followUpDate,
        assignedTo: assignedTo,
        assignedToName: assignedToName,
        notes: notes,
      );

      final response = await supabase
          .from('followups')
          .insert(followUp.toMap())
          .select();

      return UnifiedFollowUp.fromMap(response[0]);
    } catch (e) {
      print('Error creating follow-up: $e');
      rethrow;
    }
  }

  Future<List<UnifiedFollowUp>> getFollowUpsDashboard({
    required String organizationId,
    FollowUpFilter? filter,
  }) async {
    try {
      var query = supabase
          .from('followups')
          .select()
          .eq('organization_id', organizationId);

      if (filter != null) {
        final siteType = filter.siteType;
        if (siteType != null) {
          query = query.eq('site_type', siteType);
        }

        final status = filter.status;
        if (status != null) {
          query = query.eq('status', status);
        }

        final startDate = filter.startDate;
        if (startDate != null) {
          query = query.gte(
            'follow_up_date',
            startDate.toIso8601String().split('T')[0],
          );
        }

        final endDate = filter.endDate;
        if (endDate != null) {
          query = query.lte(
            'follow_up_date',
            endDate.toIso8601String().split('T')[0],
          );
        }

        final assignedTo = filter.assignedTo;
        if (assignedTo != null) {
          query = query.eq('assigned_to', assignedTo);
        }
      }

      final response =
          await query.order('follow_up_date', ascending: true);

      final followUps =
          response.map((map) => UnifiedFollowUp.fromMap(map)).toList();

      if (filter?.showOverdueOnly == true) {
        return followUps.where((fu) => fu.isOverdue).toList();
      }

      return followUps;
    } catch (e) {
      print('Error fetching follow-ups dashboard: $e');
      return [];
    }
  }

  Future<List<UnifiedFollowUp>> getBeneficiaryFollowUps({
    required String masterBeneficiaryId,
  }) async {
    try {
      final response = await supabase
          .from('followups')
          .select()
          .eq('master_beneficiary_id', masterBeneficiaryId)
          .order('follow_up_date', ascending: false);

      return response.map((map) => UnifiedFollowUp.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching beneficiary follow-ups: $e');
      return [];
    }
  }

  Future<List<UnifiedFollowUp>> getOverdueFollowUps({
    required String organizationId,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await supabase
          .from('followups')
          .select()
          .eq('organization_id', organizationId)
          .lt('follow_up_date', today)
          .eq('status', 'planned')
          .order('follow_up_date', ascending: true);

      return response.map((map) => UnifiedFollowUp.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching overdue follow-ups: $e');
      return [];
    }
  }

  Future<void> markFollowUpCompleted({
    required String followUpId,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      };
      if (notes != null) updates['notes'] = notes;

      await supabase.from('followups').update(updates).eq('id', followUpId);
    } catch (e) {
      print('Error marking follow-up completed: $e');
      rethrow;
    }
  }

  Future<void> markFollowUpMissed({
    required String followUpId,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': 'missed',
      };
      if (notes != null) updates['notes'] = notes;

      await supabase.from('followups').update(updates).eq('id', followUpId);
    } catch (e) {
      print('Error marking follow-up missed: $e');
      rethrow;
    }
  }

  Future<void> reassignFollowUp({
    required String followUpId,
    String? assignedTo,
    String? assignedToName,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (assignedTo != null) updates['assigned_to'] = assignedTo;
      if (assignedToName != null) updates['assigned_to_name'] = assignedToName;

      await supabase.from('followups').update(updates).eq('id', followUpId);
    } catch (e) {
      print('Error reassigning follow-up: $e');
      rethrow;
    }
  }

  Future<void> rescheduleFollowUp({
    required String followUpId,
    required DateTime newFollowUpDate,
  }) async {
    try {
      await supabase
          .from('followups')
          .update({
            'follow_up_date': newFollowUpDate.toIso8601String(),
            'status': 'planned',
          })
          .eq('id', followUpId);
    } catch (e) {
      print('Error rescheduling follow-up: $e');
      rethrow;
    }
  }

  Future<FollowUpStats> getFollowUpStats({
    required String organizationId,
  }) async {
    try {
      final followUps = await getFollowUpsDashboard(
        organizationId: organizationId,
      );
      return FollowUpStats.fromFollowUps(followUps);
    } catch (e) {
      print('Error getting follow-up stats: $e');
      return FollowUpStats(
        totalPlanned: 0,
        totalCompleted: 0,
        totalMissed: 0,
        totalOverdue: 0,
        completionRate: 0,
        bySiteType: {},
        byStatus: {},
      );
    }
  }

  Future<int> getTodayFollowUpCount({
    required String organizationId,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await supabase
          .from('followups')
          .select('count')
          .eq('organization_id', organizationId)
          .eq('follow_up_date', today)
          .eq('status', 'planned')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      print('Error getting today follow-up count: $e');
      return 0;
    }
  }

  Future<int> getThisWeekFollowUpCount({
    required String organizationId,
  }) async {
    try {
      final today = DateTime.now();
      final weekEnd = today.add(Duration(days: 7));

      final response = await supabase
          .from('followups')
          .select('count')
          .eq('organization_id', organizationId)
          .gte('follow_up_date', today.toIso8601String().split('T')[0])
          .lte('follow_up_date', weekEnd.toIso8601String().split('T')[0])
          .eq('status', 'planned')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      print('Error getting this week follow-up count: $e');
      return 0;
    }
  }

  Future<Map<String, int>> getFollowUpCountBySiteType({
    required String organizationId,
  }) async {
    try {
      final response = await supabase
          .from('followups')
          .select('site_type')
          .eq('organization_id', organizationId)
          .eq('status', 'planned');

      final counts = <String, int>{};
      for (final item in response) {
        final siteType = item['site_type'] as String;
        counts[siteType] = (counts[siteType] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error getting follow-up count by site type: $e');
      return {};
    }
  }

  Future<void> deleteFollowUp({
    required String followUpId,
  }) async {
    try {
      await supabase.from('followups').delete().eq('id', followUpId);
    } catch (e) {
      print('Error deleting follow-up: $e');
      rethrow;
    }
  }
}
