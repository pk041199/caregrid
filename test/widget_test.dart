import 'package:flutter_test/flutter_test.dart';
import 'package:caregrid/models/followup_models.dart';
import 'package:caregrid/services/auth_service.dart';

void main() {
  test('Auth error codes are stable', () {
    expect(AuthErrorCode.values, contains(AuthErrorCode.invalidCredentials));
    expect(AuthErrorCode.values, contains(AuthErrorCode.missingSelection));
    expect(AuthErrorCode.values, contains(AuthErrorCode.networkError));
    expect(AuthErrorCode.values, contains(AuthErrorCode.unknown));
  });

  test('OrganizationOption maps raw data safely', () {
    final option = OrganizationOption.fromMap({
      'id': 'org-1',
      'name': 'Demo Org',
    });

    expect(option.id, 'org-1');
    expect(option.name, 'Demo Org');
  });

  test('Follow-up status labels reflect overdue and completion state', () {
    final overdueFollowUp = UnifiedFollowUp(
      organizationId: 'org-1',
      masterBeneficiaryId: 'benef-1',
      siteType: 'clinic',
      siteId: 'site-1',
      followUpDate: DateTime.now().subtract(const Duration(days: 2)),
      status: 'planned',
    );

    final completedFollowUp = UnifiedFollowUp(
      organizationId: 'org-1',
      masterBeneficiaryId: 'benef-2',
      siteType: 'field',
      siteId: 'site-2',
      followUpDate: DateTime.now().add(const Duration(days: 3)),
      status: 'completed',
    );

    expect(overdueFollowUp.statusLabel, 'Overdue');
    expect(completedFollowUp.statusLabel, 'Completed');
  });
}
