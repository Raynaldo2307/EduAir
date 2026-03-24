import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/features/auth/application/forgot_password_notifier.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────
// Launched from sign_in_form.dart when user taps "Forgot password?"
// Step 1: enter email → receive 6-digit code
// Step 2: enter code + new password → login
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _emailController       = TextEditingController();
  final _codeController        = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController     = TextEditingController();

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  bool _obscureNew     = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  InputDecoration _field(BuildContext context, {String? hint, Widget? suffix}) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      filled:    true,
      fillColor: isDark
          ? cs.surfaceContainerHighest
          : cs.primary.withValues(alpha: 0.06),
      hintText:  hint,
      hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.2), width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.2), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      suffixIcon: suffix,
    );
  }

  Widget _errorBanner(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE9E9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFE25563).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFB91C1C), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13.5),
              ),
            ),
          ],
        ),
      );

  // ── Step 1 ─────────────────────────────────────────────────────────────────
  Widget _buildStep1(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final txt   = Theme.of(context).textTheme;
    final state = ref.watch(forgotPasswordNotifierProvider);

    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EduAir logo
          Center(
            child: Image.asset(
              'assets/images/eduair_logo.png',
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Forgot your password?',
            style: txt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your school email and we\'ll send you a 6-digit reset code.',
            style: txt.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          if (state.errorMessage != null) ...[
            _errorBanner(state.errorMessage!),
            const SizedBox(height: 16),
          ],

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: cs.onSurface),
            decoration: _field(context, hint: 'Enter your school email'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Send code button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: state.isLoading
                  ? null
                  : () async {
                      if (!_step1Key.currentState!.validate()) return;
                      FocusScope.of(context).unfocus();
                      await ref
                          .read(forgotPasswordNotifierProvider.notifier)
                          .sendCode(_emailController.text.trim());
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: state.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Text(
                      'Send Code',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Back to sign in
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Back to Sign In',
                style: TextStyle(color: cs.primary, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2 ─────────────────────────────────────────────────────────────────
  Widget _buildStep2(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final txt   = Theme.of(context).textTheme;
    final state = ref.watch(forgotPasswordNotifierProvider);

    return Form(
      key: _step2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EduAir logo
          Center(
            child: Image.asset(
              'assets/images/eduair_logo.png',
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Check your email',
            style: txt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: txt.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'We sent a 6-digit code to '),
                TextSpan(
                  text: state.email ?? '',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '. Enter it below.'),
              ],
            ),
          ),
          const SizedBox(height: 28),

          if (state.errorMessage != null) ...[
            _errorBanner(state.errorMessage!),
            const SizedBox(height: 16),
          ],

          // 6-digit code
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
            ),
            decoration: _field(context, hint: '000000').copyWith(
              counterText: '',
              hintStyle: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.3),
                fontSize: 22,
                letterSpacing: 8,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter the 6-digit code';
              if (v.length < 6) return 'Code must be 6 digits';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // New password
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            style: TextStyle(color: cs.onSurface),
            decoration: _field(
              context,
              hint: 'New password',
              suffix: IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility_off : Icons.visibility,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a new password';
              if (v.length < 8) return 'Min 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm password
          TextFormField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            style: TextStyle(color: cs.onSurface),
            decoration: _field(
              context,
              hint: 'Confirm new password',
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _newPasswordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Reset password button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: state.isLoading
                  ? null
                  : () async {
                      if (!_step2Key.currentState!.validate()) return;
                      FocusScope.of(context).unfocus();

                      // Capture before async gap
                      final navigator  = Navigator.of(context);
                      final messenger  = ScaffoldMessenger.of(context);

                      final success = await ref
                          .read(forgotPasswordNotifierProvider.notifier)
                          .resetPassword(
                            _codeController.text.trim(),
                            _newPasswordController.text.trim(),
                          );

                      if (success && mounted) {
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Password reset! Please log in.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: state.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Text(
                      'Reset Password',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Didn't get the code — go back to step 1
          Center(
            child: TextButton(
              onPressed: state.isLoading
                  ? null
                  : () => ref
                      .read(forgotPasswordNotifierProvider.notifier)
                      .backToStep1(),
              child: Text(
                "Didn't get the code? Try again",
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final state = ref.watch(forgotPasswordNotifierProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: cs.onSurface),
        title: Text(
          state.step == 1 ? 'Reset Password' : 'Enter Code',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: state.step == 1
              ? _buildStep1(context)
              : _buildStep2(context),
        ),
      ),
    );
  }
}
