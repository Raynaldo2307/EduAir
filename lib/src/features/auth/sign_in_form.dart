import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/models/app_user.dart';
import 'package:edu_air/src/features/auth/sign_up_form.dart';
import 'package:edu_air/src/features/auth/reset_password_page.dart'; //

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: AppTheme.accent.withValues(alpha: 0.2),
      hintText: hintText,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.2),
      ),

      // When the field is enabled but Not focused
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.2),
      ),

      //When the field is focused (typing)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.8),
      ),

      // red border when there's a validation
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),

      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      suffixIcon: suffixIcon,
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _routeForRole(String role, String? schoolId) {
    if (role.isEmpty) return '/selectRole';
    if (schoolId == null || schoolId.isEmpty) return '/selectSchool';
    if (role == 'student') return '/studentHome';
    if (role == 'teacher' || role == 'admin' || role == 'principal') {
      return '/teacherHome';
    }
    return '/onboarding';
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final navigator = Navigator.of(context);
    final authRepo = ref.read(authApiRepositoryProvider);
    final userNotifier = ref.read(userProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Call Node API — saves JWT automatically inside the repository.
      final data = await authRepo.login(email: email, password: password);
      final userData = data['user'] as Map<String, dynamic>;

      final role = userData['role'] ?? '';
      final schoolId = userData['schoolId']?.toString();

      userNotifier.state = AppUser(
        uid: userData['id'].toString(),
        firstName: userData['firstName'] ?? '',
        lastName: userData['lastName'] ?? '',
        email: userData['email'] ?? '',
        phone: '',
        role: role,
        schoolId: schoolId,
        defaultShiftType:  userData['defaultShiftType']  as String?,
        isShiftSchool:     userData['isShiftSchool']  as bool? ?? false,
        studentId:         userData['studentId']         as String?,
        currentShift:      userData['currentShift']      as String?,
        sex:               userData['sex']               as String?,
        classId:           userData['classId']           as String?,
        className:         userData['className']         as String?,
        gradeLevel:        userData['gradeLevel']        as String?,
        homeroomClassId:   userData['homeroomClassId']   as String?,
        homeroomClassName: userData['homeroomClassName'] as String?,
      );

      if (!mounted) return;

      final targetRoute = _routeForRole(role, schoolId);
      navigator.pushReplacementNamed(targetRoute);
    } catch (e) {
      dev.log('Login error: $e', name: 'SignInPage');
      if (!mounted) return;

      String message;
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        message = 'Cannot reach server. Check your connection and try again.';
      } else if (e is DioException && e.response?.statusCode == 401) {
        message = 'Invalid email or password. Please try again.';
      } else {
        message = 'Something went wrong. Please try again.';
      }

      setState(() => _errorMessage = message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final navigator = Navigator.of(context);
    final authService = ref.read(authServiceProvider);
    final userNotifier = ref.read(userProvider.notifier);

    setState(() => _isSubmitting = true);

    try {
      final user = await authService.signInWithGoogle();

      // null = user cancelled — reset silently, no snackbar
      if (user == null) return;

      userNotifier.state = user;
      if (!mounted) return;

      final targetRoute = _routeForRole(user.role, user.schoolId);
      _showSnack('Signed in with Google');
      navigator.pushReplacementNamed(targetRoute);
    } catch (e) {
      // Only reaches here on a real error (network, Firebase config, etc.)
      if (!mounted) return;
      _showSnack(
        'Google sign-in is not available right now. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: CircleAvatar(
                    radius: 34,
                    backgroundImage: const AssetImage(
                      'assets/images/eduair_logo.png',
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Log in',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hello, welcome back to your account.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Inline error banner — shown when login fails
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE9E9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFE25563).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Color(0xFFB91C1C),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFB91C1C),
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) {
                          if (_errorMessage != null) {
                            setState(() => _errorMessage = null);
                          }
                        },
                        decoration: _inputDecoration(
                          hintText: 'Enter your email',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onChanged: (_) {
                          if (_errorMessage != null) {
                            setState(() => _errorMessage = null);
                          }
                        },
                        decoration: _inputDecoration(
                          hintText: 'Enter your password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppTheme.textPrimary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ResetPasswordPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Email login button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Log in',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: const [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('or'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Google sign-in
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Image.asset(
                            'assets/images/google.png',
                            height: 24,
                            semanticLabel: 'Continue with Google',
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Sign up row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(fontSize: 15),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SignUpPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Sign up',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
