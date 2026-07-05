import 'package:uuid/uuid.dart';

class UnifiedFollowUp {
  final String id;
  final String organizationId;
  final String masterBeneficiaryId;
  final String siteType;
  final String siteId;
  final String? formId;
  final DateTime followUpDate;
  final String status;
  final String? assignedTo;
  final String? assignedToName;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;

  UnifiedFollowUp({
    String? id,
    required this.organizationId,
    required this.masterBeneficiaryId,
    required this.siteType,
    required this.siteId,
    this.formId,
    required this.followUpDate,
    this.status = 'planned',
    this.assignedTo,
    this.assignedToName,
    DateTime? createdAt,
    this.completedAt,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'organization_id': organizationId,
        'master_beneficiary_id': masterBeneficiaryId,
        'site_type': siteType,
        'site_id': siteId,
        'form_id': formId,
        'follow_up_date': followUpDate.toIso8601String(),
        'status': status,
        'assigned_to': assignedTo,
        'assigned_to_name': assignedToName,
        'created_at': createdAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'notes': notes,
      };

  factory UnifiedFollowUp.fromMap(Map<String, dynamic> map) => UnifiedFollowUp(
        id: map['id'],
        organizationId: map['organization_id'],
        masterBeneficiaryId: map['master_beneficiary_id'],
        siteType: map['site_type'],
        siteId: map['site_id'],
        formId: map['form_id'],
        followUpDate: DateTime.parse(map['follow_up_date']),
        status: map['status'] ?? 'planned',
        assignedTo: map['assigned_to'],
        assignedToName: map['assigned_to_name'],
        createdAt: DateTime.parse(map['created_at']),
        completedAt: map['completed_at'] != null
            ? DateTime.parse(map['completed_at'])
            : null,
        notes: map['notes'],
      );

  UnifiedFollowUp copyWith({
    String? id,
    String? organizationId,
    String? masterBeneficiaryId,
    String? siteType,
    String? siteId,
    String? formId,
    DateTime? followUpDate,
    String? status,
    String? assignedTo,
    String? assignedToName,
    DateTime? createdAt,
    DateTime? completedAt,
    String? notes,
  }) =>
      UnifiedFollowUp(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        masterBeneficiaryId: masterBeneficiaryId ?? this.masterBeneficiaryId,
        siteType: siteType ?? this.siteType,
        siteId: siteId ?? this.siteId,
        formId: formId ?? this.formId,
        followUpDate: followUpDate ?? this.followUpDate,
        status: status ?? this.status,
        assignedTo: assignedTo ?? this.assignedTo,
        assignedToName: assignedToName ?? this.assignedToName,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt ?? this.completedAt,
        notes: notes ?? this.notes,
      );

  bool get isOverdue =>
      DateTime.now().isAfter(followUpDate) && status == 'planned';

  bool get isUpcoming =>
      DateTime.now().isBefore(followUpDate) && status == 'planned';

  String get statusLabel {
    final normalized = status.toLowerCase();
    if (normalized == 'completed') return 'Completed';
    if (normalized == 'doctor reviewed') return 'Doctor Reviewed';
    if (normalized == 'missed') return 'Missed';
    if (normalized == 'rescheduled') return 'Rescheduled';
    if (isOverdue) return 'Overdue';
    if (isUpcoming) return 'Upcoming';
    return 'Planned';
  }

  int get daysUntilFollowUp =>
      followUpDate.difference(DateTime.now()).inDays;

  int get daysSinceFollowUp =>
      DateTime.now().difference(followUpDate).inDays;
}

class FollowUpFilter {
  final String? siteType;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? assignedTo;
  final bool? showOverdueOnly;

  FollowUpFilter({
    this.siteType,
    this.status,
    this.startDate,
    this.endDate,
    this.assignedTo,
    this.showOverdueOnly = false,
  });

  Map<String, dynamic> toMap() => {
        'site_type': siteType,
        'status': status,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'assigned_to': assignedTo,
        'show_overdue_only': showOverdueOnly,
      };

  bool matches(UnifiedFollowUp followUp) {
    if (siteType != null && followUp.siteType != siteType) return false;
    if (status != null && followUp.status != status) return false;
    if (startDate != null && followUp.followUpDate.isBefore(startDate!)) {
      return false;
    }
    if (endDate != null && followUp.followUpDate.isAfter(endDate!)) {
      return false;
    }
    if (assignedTo != null && followUp.assignedTo != assignedTo) return false;
    if (showOverdueOnly == true && !followUp.isOverdue) return false;
    return true;
  }
}

class FollowUpStats {
  final int totalPlanned;
  final int totalCompleted;
  final int totalMissed;
  final int totalOverdue;
  final double completionRate;
  final Map<String, int> bySiteType;
  final Map<String, int> byStatus;

  FollowUpStats({
    required this.totalPlanned,
    required this.totalCompleted,
    required this.totalMissed,
    required this.totalOverdue,
    required this.completionRate,
    required this.bySiteType,
    required this.byStatus,
  });

  Map<String, dynamic> toMap() => {
        'total_planned': totalPlanned,
        'total_completed': totalCompleted,
        'total_missed': totalMissed,
        'total_overdue': totalOverdue,
        'completion_rate': completionRate,
        'by_site_type': bySiteType,
        'by_status': byStatus,
      };

  factory FollowUpStats.fromFollowUps(List<UnifiedFollowUp> followUps) {
    int planned = 0,
        completed = 0,
        missed = 0,
        overdue = 0;
    final bySiteType = <String, int>{};
    final byStatus = <String, int>{};

    for (final fu in followUps) {
      bySiteType[fu.siteType] = (bySiteType[fu.siteType] ?? 0) + 1;
      byStatus[fu.status] = (byStatus[fu.status] ?? 0) + 1;

      if (fu.status == 'planned') {
        planned++;
        if (fu.isOverdue) overdue++;
      } else if (fu.status == 'completed') {
        completed++;
      } else if (fu.status == 'missed') {
        missed++;
      }
    }

    final total = followUps.length;
    final completionRate = total > 0
        ? (completed / (completed + missed)) * 100.0
        : 0.0;

    return FollowUpStats(
      totalPlanned: planned,
      totalCompleted: completed,
      totalMissed: missed,
      totalOverdue: overdue,
      completionRate: completionRate,
      bySiteType: bySiteType,
      byStatus: byStatus,
    );
  }
}
