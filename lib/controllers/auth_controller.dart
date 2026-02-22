import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._authService);

  final AuthService _authService;

  bool _isLoading = false;
  String? _errorMessage;
  List<OrganizationOption> _organizations = [];
  List<OrganizationUserOption> _users = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<OrganizationOption> get organizations => _organizations;
  List<OrganizationUserOption> get users => _users;

  Future<void> loadOrganizations() async {
    _startRequest();

    try {
      _organizations = await _authService.getOrganizations();
      if (_organizations.isEmpty) {
        _errorMessage =
            'No organizations found. Check organizations table data and select policy.';
      }
      _finishRequest();
    } on AuthFailure catch (failure) {
      _errorMessage = _toUserMessage(failure);
      _finishRequest();
    } catch (_) {
      _errorMessage = 'Failed to load organizations.';
      _finishRequest();
    }
  }

  Future<bool> signIn({
    required String organizationId,
    required String userId,
    required String password,
  }) async {
    _startRequest();

    try {
      await _authService.signIn(
        organizationId: organizationId,
        userId: userId,
        password: password,
      );
      _finishRequest();
      return true;
    } on AuthFailure catch (failure) {
      _errorMessage = _toUserMessage(failure);
      _finishRequest();
      return false;
    } catch (_) {
      _errorMessage = 'Login failed. Please try again.';
      _finishRequest();
      return false;
    }
  }

  Future<void> loadUsersForOrganization(String organizationId) async {
    _users = [];
    _startRequest();

    try {
      _users = await _authService.getOrganizationUsers(organizationId);
      if (_users.isEmpty) {
        _errorMessage = 'No users found for selected organization.';
      }
      _finishRequest();
    } on AuthFailure catch (failure) {
      _errorMessage = _toUserMessage(failure);
      _finishRequest();
    } catch (_) {
      _errorMessage = 'Failed to load users.';
      _finishRequest();
    }
  }

  Future<bool> resetPassword({
    required String organizationId,
    required String identifier,
    required String newPassword,
  }) async {
    _startRequest();

    try {
      await _authService.resetPassword(
        organizationId: organizationId,
        identifier: identifier,
        newPassword: newPassword,
      );
      _finishRequest();
      return true;
    } on AuthFailure catch (failure) {
      _errorMessage = _toUserMessage(failure);
      _finishRequest();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to reset password.';
      _finishRequest();
      return false;
    }
  }

  Future<void> signInDemo(String role) async {
    _startRequest();
    try {
      await _authService.signInDemo(role: role);
      _finishRequest();
    } catch (_) {
      _errorMessage = 'Demo login failed.';
      _finishRequest();
    }
  }

  void _startRequest() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _finishRequest() {
    _isLoading = false;
    notifyListeners();
  }

  String _toUserMessage(AuthFailure failure) {
    switch (failure.code) {
      case AuthErrorCode.invalidCredentials:
        return 'Invalid user ID or password.';
      case AuthErrorCode.missingSelection:
        return 'Please select an organization.';
      case AuthErrorCode.networkError:
        return failure.message.isNotEmpty
            ? failure.message
            : 'Network or database error. Please retry.';
      case AuthErrorCode.unknown:
        return failure.message.isNotEmpty
            ? failure.message
            : 'Authentication failed.';
    }
  }
}
