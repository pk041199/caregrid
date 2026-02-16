import 'package:flutter_test/flutter_test.dart';
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
}
