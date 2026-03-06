import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/core/app_providers.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false; // prevents double-taps / multiple requests
  bool _termsAccepted = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitForm() async {
    // Accounts are created by your school admin.
    // Students and teachers do not self-register.
    _showSnack('Contact your school admin to create your account.');
  }

  Future<void> _handleGoogleSignUp() async {
    // Same UX pattern as email sign-up
    setState(() => _isSubmitting = true);

    final authService = ref.read(authServiceProvider);
    final userNotifier = ref.read(userProvider.notifier);
    final navigator = Navigator.of(context);

    try {
      final user = await authService.signInWithGoogle();

      // null = user cancelled — reset silently, no snackbar
      if (user == null) return;

      userNotifier.state = user;
      if (!mounted) return;
      _showSnack('Google sign-in successful!');
      navigator.pushReplacementNamed('/selectRole');
    } catch (e) {
      // Only reaches here on a real error (network, Firebase config, etc.)
      if (!mounted) return;
      _showSnack('Google sign-in is not available right now. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: Text(
          'Sign Up',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full name
              Text('Full Name', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(hintText: 'Enter your full name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              Text('Email', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration(hintText: 'Enter your email'),
                keyboardType: TextInputType.emailAddress,
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

              // Phone number
              Text('Phone Number', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration(
                  hintText: 'Enter your phone number',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.length < 10) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              Text('Password', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                decoration: _inputDecoration(
                  hintText: 'Enter your password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Min 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Terms & conditions
              Row(
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    onChanged: (val) {
                      setState(() {
                        _termsAccepted = val ?? false;
                      });
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Navigate to Terms and Conditions page
                      },
                      child: const Text(
                        'I agree to the Terms & Conditions',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Create account button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.white,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 16, color: AppTheme.white),
                        ),
                ),
              ),

              const SizedBox(height: 16),

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

              // Google sign-up
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _handleGoogleSignUp,
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
            ],
          ),
        ),
      ),
    );
  }
}
