// lib/src/features/auth/reset_password_page.dart
//
// Password reset is handled by the school administrator.
// EduAir accounts are created and managed by admins — users do not
// self-manage passwords. Contact your admin to reset.

import 'package:flutter/material.dart';
import 'package:edu_air/src/core/app_theme.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final txt    = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'Reset Password',
          style: txt.titleLarge?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: cs.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                size: 32,
                color: cs.primary,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Need to reset your password?',
              style: txt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'EduAir accounts are managed by your school administrator. '
              'To reset your password, please contact them directly.',
              style: txt.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
                height: 1.6,
              ),
            ),

            const SizedBox(height: 28),

            // Info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? cs.surfaceContainerHighest
                    : AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 18,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Contact your administrator',
                        style: txt.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ask your school admin or principal to reset '
                    'your password from the admin panel.',
                    style: txt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Sign In',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
