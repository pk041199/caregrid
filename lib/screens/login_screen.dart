import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  late final AuthController _authController;
  String? _selectedOrganizationId;
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(AuthService());
    _authController.loadOrganizations();
    if (AuthService().currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _authController.signIn(
      organizationId: _selectedOrganizationId ?? '',
      userId: _selectedUserId ?? '',
      password: _passwordController.text,
    );
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    if (_selectedOrganizationId == null || _selectedOrganizationId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select organization first.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final identifierController = TextEditingController(
      text: _selectedUserId ?? '',
    );
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final didReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: identifierController,
                  decoration: const InputDecoration(
                    labelText: 'User ID or Email',
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'User ID or email is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  obscureText: true,
                  validator: (value) {
                    final password = value ?? '';
                    if (password.isEmpty) return 'New password is required';
                    if (password.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration:
                      const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                  validator: (value) {
                    if ((value ?? '') != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final success = await _authController.resetPassword(
                  organizationId: _selectedOrganizationId!,
                  identifier: identifierController.text.trim(),
                  newPassword: newPasswordController.text,
                );

                if (!dialogContext.mounted) return;

                if (success) {
                  Navigator.of(dialogContext).pop(true);
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _authController.errorMessage ?? 'Password reset failed.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    identifierController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (didReset == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. You can now login.')),
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CareGrid Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: AnimatedBuilder(
            animation: _authController,
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                  const Text(
                    'CareGrid - Public Health Information System',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedOrganizationId,
                    decoration:
                        const InputDecoration(labelText: 'Select Organization'),
                    items: _authController.organizations
                        .map(
                          (org) => DropdownMenuItem<String>(
                            value: org.id,
                            child: Text(org.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedOrganizationId = value;
                        _selectedUserId = null;
                      });
                      if (value != null && value.isNotEmpty) {
                        _authController.loadUsersForOrganization(value);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Organization is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUserId,
                    decoration: const InputDecoration(labelText: 'Select User'),
                    items: _authController.users
                        .map(
                          (user) => DropdownMenuItem<String>(
                            value: user.userId,
                            child: Text(
                              '${user.displayName} (${user.userId})'
                              '${user.role.isNotEmpty ? ' - ${user.role}' : ''}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUserId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'User selection is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) {
                      final password = value ?? '';
                      if (password.isEmpty) return 'Password is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_authController.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _authController.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  _authController.isLoading
                      ? const CircularProgressIndicator()
                      : Column(
                          children: [
                        ElevatedButton(
                          onPressed: _login,
                          child: const Text('Login'),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () async {
                                await _authController.signInDemo('Doctor');
                                if (!mounted) return;
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const HomeScreen(),
                                  ),
                                );
                              },
                              child: const Text('Demo Doctor'),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                await _authController.signInDemo('Field Staff');
                                if (!mounted) return;
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const HomeScreen(),
                                  ),
                                );
                              },
                              child: const Text('Demo Field Staff'),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text('Forgot Password'),
                        ),
                          ],
                        ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
