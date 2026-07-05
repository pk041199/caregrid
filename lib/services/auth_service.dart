import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

enum AuthErrorCode {
  invalidCredentials,
  missingSelection,
  networkError,
  unknown,
}

class AuthFailure implements Exception {
  AuthFailure(this.code, this.message);

  final AuthErrorCode code;
  final String message;
}

class OrganizationOption {
  OrganizationOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory OrganizationOption.fromMap(Map<String, dynamic> map) {
    final rawName =
        map['name'] ?? map['organization_name'] ?? map['org_name'] ?? '';

    return OrganizationOption(
      id: map['id'].toString(),
      name: rawName.toString(),
    );
  }
}

class OrganizationUserSession {
  OrganizationUserSession({
    required this.userId,
    required this.fullName,
    required this.role,
    required this.organizationId,
    required this.organizationName,
  });

  final String userId;
  final String fullName;
  final String role;
  final String organizationId;
  final String organizationName;
}

class OrganizationUserOption {
  OrganizationUserOption({
    required this.userId,
    required this.displayName,
    required this.role,
    this.email,
  });

  final String userId;
  final String displayName;
  final String role;
  final String? email;

  factory OrganizationUserOption.fromMap(Map<String, dynamic> map) {
    final id = (map['user_id'] ?? map['id'] ?? '').toString().trim();
    final name = (map['full_name'] ?? map['name'] ?? id).toString().trim();
    final role = (map['role'] ?? map['user_role'] ?? '').toString().trim();
    final emailRaw = map['email'];

    return OrganizationUserOption(
      userId: id,
      displayName: name.isEmpty ? id : name,
      role: role,
      email: emailRaw?.toString(),
    );
  }
}

class AuthService {
  AuthService._internal();

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final SupabaseClient _client = Supabase.instance.client;
  final StreamController<OrganizationUserSession?> _authStateController =
      StreamController<OrganizationUserSession?>.broadcast();

  OrganizationUserSession? _currentSession;

  Stream<OrganizationUserSession?> get authStateChanges =>
      _authStateController.stream;

  OrganizationUserSession? get currentSession => _currentSession;

  Future<List<OrganizationOption>> getOrganizations() async {
    try {
      final response = await _client.from('organizations').select();

      final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();

      final filtered = rows.where((row) {
        // If is_active column exists, only show active rows; otherwise allow all.
        return row['is_active'] == null || row['is_active'] == true;
      });

      final organizations = filtered
          .map(OrganizationOption.fromMap)
          .where((org) => org.id.isNotEmpty && org.name.isNotEmpty)
          .toList();

      organizations.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      return organizations;
    } on PostgrestException catch (e) {
      throw AuthFailure(
        AuthErrorCode.networkError,
        'Organizations query failed: ${e.message}',
      );
    } catch (_) {
      throw AuthFailure(AuthErrorCode.unknown, 'Failed to load organizations');
    }
  }

  Future<List<OrganizationUserOption>> getOrganizationUsers(
    String organizationId,
  ) async {
    if (organizationId.isEmpty) return [];

    try {
      final response = await _client
          .from('organization_users')
          .select()
          .eq('organization_id', organizationId);

      final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();

      final users = rows
          .where((row) => row['is_active'] == null || row['is_active'] == true)
          .map(OrganizationUserOption.fromMap)
          .where((user) => user.userId.isNotEmpty)
          .toList();

      users.sort(
        (a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );

      return users;
    } on PostgrestException catch (e) {
      throw AuthFailure(
        AuthErrorCode.networkError,
        'Users query failed: ${e.message}',
      );
    } catch (_) {
      throw AuthFailure(AuthErrorCode.unknown, 'Failed to load users');
    }
  }

  Future<void> signIn({
    required String organizationId,
    required String userId,
    required String password,
  }) async {
    if (organizationId.isEmpty) {
      throw AuthFailure(
        AuthErrorCode.missingSelection,
        'Please select an organization.',
      );
    }

    try {
      final record = await _verifyByRpc(
        organizationId: organizationId,
        identifier: userId.trim(),
        password: password,
      );

      if (record == null) {
        throw AuthFailure(
          AuthErrorCode.invalidCredentials,
          'Invalid user ID/email or password for this organization.',
        );
      }

      final organization = await _client
          .from('organizations')
          .select()
          .eq('id', record['organization_id'])
          .maybeSingle();

      final orgMap = organization is Map<String, dynamic> ? organization : null;
      final orgName = (orgMap?['name'] ??
              orgMap?['organization_name'] ??
              orgMap?['org_name'] ??
              '')
          .toString();

      _currentSession = OrganizationUserSession(
        userId: (record['user_id'] ?? record['id'] ?? '').toString(),
        fullName: (record['full_name'] ?? record['name'] ?? '').toString(),
        role: (record['role'] ?? record['user_role'] ?? '').toString(),
        organizationId: (record['organization_id'] ?? '').toString(),
        organizationName: orgName,
      );
      _authStateController.add(_currentSession);
    } on PostgrestException catch (e) {
      if (e.message.toLowerCase().contains('verify_org_user_login_v2')) {
        throw AuthFailure(
          AuthErrorCode.unknown,
          'RPC verify_org_user_login_v2 is missing. Create it in Supabase SQL editor.',
        );
      }
      throw AuthFailure(
        AuthErrorCode.networkError,
        'Login query failed: ${e.message}',
      );
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw AuthFailure(AuthErrorCode.unknown, 'Unexpected sign-in error');
    }
  }

  Future<void> signOut() async {
    _currentSession = null;
    _authStateController.add(null);
  }

  Future<void> signInDemo({
    required String role,
  }) async {
    final normalizedRole = role.toLowerCase();
    final isDoctor = normalizedRole.contains('doctor');
    final isPatient = normalizedRole.contains('patient');
    final userId = isDoctor
        ? 'DEMO-DR'
        : isPatient
            ? 'DEMO-PATIENT'
            : 'DEMO-FIELD';
    _currentSession = OrganizationUserSession(
      userId: userId,
      fullName: isDoctor
          ? 'Demo Doctor'
          : isPatient
              ? 'Demo Patient'
              : 'Demo $role',
      role: role,
      organizationId: 'demo-org',
      organizationName: 'Demo Organization',
    );
    _authStateController.add(_currentSession);
  }

  Future<void> resetPassword({
    required String organizationId,
    required String identifier,
    required String newPassword,
  }) async {
    if (organizationId.isEmpty) {
      throw AuthFailure(
        AuthErrorCode.missingSelection,
        'Please select an organization.',
      );
    }

    if (identifier.trim().isEmpty) {
      throw AuthFailure(
        AuthErrorCode.invalidCredentials,
        'User ID or email is required.',
      );
    }

    try {
      await _resetPasswordByRpc(
        organizationId: organizationId,
        identifier: identifier.trim(),
        newPassword: newPassword,
      );
    } on PostgrestException catch (e) {
      throw AuthFailure(
        AuthErrorCode.networkError,
        'Reset query failed: ${e.message}',
      );
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw AuthFailure(AuthErrorCode.unknown, 'Password reset failed.');
    }
  }

  String? get currentUserRole => _currentSession?.role;
  String? get currentUserName => _currentSession?.fullName;
  String? get currentOrganizationName => _currentSession?.organizationName;

  Future<String?> getUserRole() async {
    return _currentSession?.role;
  }

  void dispose() {
    _authStateController.close();
  }

  Map<String, dynamic>? _coerceRpcRecord(dynamic response) {
    if (response == null) return null;

    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is List && response.isNotEmpty && response.first is Map<String, dynamic>) {
      return response.first as Map<String, dynamic>;
    }

    return null;
  }

  Future<Map<String, dynamic>?> _verifyByRpc({
    required String organizationId,
    required String identifier,
    required String password,
  }) async {
    final attempts = <({String fn, Map<String, dynamic> params})>[
      (
        fn: 'verify_org_user_login_v2',
        params: {
          'p_org_id': organizationId,
          'p_identifier': identifier,
          'p_pwd': password,
        }
      ),
      (
        fn: 'verify_org_user_login_v2',
        params: {
          'organization_id': organizationId,
          'identifier': identifier,
          'pwd': password,
        }
      ),
      (
        fn: 'verify_org_user_login',
        params: {
          'p_organization_id': organizationId,
          'p_identifier': identifier,
          'p_password': password,
        }
      ),
    ];

    PostgrestException? lastError;
    for (final attempt in attempts) {
      try {
        final response = await _client.rpc(attempt.fn, params: attempt.params);
        final record = _coerceRpcRecord(response);
        if (record != null) return record;
      } on PostgrestException catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      throw lastError;
    }

    return null;
  }

  Future<void> _resetPasswordByRpc({
    required String organizationId,
    required String identifier,
    required String newPassword,
  }) async {
    final attempts = <({String fn, Map<String, dynamic> params})>[
      (
        fn: 'forgot_org_user_password_v1',
        params: {
          'p_org_id': organizationId,
          'p_identifier': identifier,
          'p_new_password': newPassword,
        }
      ),
      (
        fn: 'forgot_org_user_password_v1',
        params: {
          'organization_id': organizationId,
          'identifier': identifier,
          'new_password': newPassword,
        }
      ),
    ];

    PostgrestException? lastError;
    for (final attempt in attempts) {
      try {
        final response = await _client.rpc(attempt.fn, params: attempt.params);
        if (response == null || response == true || response == 'ok' || response == 1) {
          return;
        }
        if (response is List && response.isNotEmpty) {
          return;
        }
      } on PostgrestException catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      if (lastError.message.toLowerCase().contains('forgot_org_user_password_v1')) {
        throw AuthFailure(
          AuthErrorCode.unknown,
          'RPC forgot_org_user_password_v1 is missing. Create it in Supabase SQL editor.',
        );
      }
      throw lastError;
    }

    throw AuthFailure(AuthErrorCode.unknown, 'Password reset failed.');
  }
}
