class MedicalRolePolicy {
  static String normalize(String? rawRole) {
    final role = (rawRole ?? '').trim().toLowerCase();
    if (role.isEmpty) return 'collector';
    if (role.contains('super') || role == 'admin' || role.contains('creator')) {
      return 'creator';
    }
    if (role.contains('manager')) return 'manager';
    if (role.contains('curator')) return 'curator';
    if (role.contains('doctor') || role.contains('physician')) return 'doctor';
    if (role.contains('viewer') || role.contains('read only')) return 'viewer';
    if (role.contains('field') || role.contains('collector')) return 'collector';
    return role;
  }

  static String label(String? rawRole) {
    switch (normalize(rawRole)) {
      case 'creator':
        return 'Medical Creator';
      case 'manager':
        return 'Program Manager';
      case 'curator':
        return 'Clinical Curator';
      case 'doctor':
        return 'Doctor';
      case 'viewer':
        return 'Read-only Viewer';
      case 'collector':
        return 'Field Collector';
      default:
        return (rawRole ?? '').trim().isEmpty ? 'Field Collector' : rawRole!.trim();
    }
  }

  static bool canOpenAdminPanel(String? rawRole) {
    final role = normalize(rawRole);
    return role == 'creator' || role == 'manager';
  }

  static bool canCreateOrganization(String? rawRole) {
    return normalize(rawRole) == 'creator';
  }

  static bool canReviewClinical(String? rawRole) {
    final role = normalize(rawRole);
    return role == 'doctor' || role == 'curator' || role == 'manager';
  }

  static bool canEditAssessmentPlan(String? rawRole) {
    final role = normalize(rawRole);
    return role == 'doctor' ||
        role == 'curator' ||
        role == 'manager' ||
        role == 'creator';
  }

  static bool canFillFieldForms(String? rawRole) {
    final role = normalize(rawRole);
    return role != 'viewer';
  }
}
