// lib/src/features/shell/select_school.dart
//
// NoSchoolPage — shown when a logged-in user has no schoolId assigned.
//
// School assignment is an admin action. Users are ENROLLED or EMPLOYED by a
// school — they do not self-select. The admin creates the account with the
// correct school_id. If a user lands here something is incomplete with their
// account setup.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';

class NoSchoolPage extends ConsumerWidget {
  const NoSchoolPage({super.key});

  Future<void> _signOut(WidgetRef ref, BuildContext context) async {
    final tokenStorage = ref.read(tokenStorageProvider);
    await tokenStorage.delete();
    ref.read(userProvider.notifier).state = null;
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (_) => false);
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'admin':      return const Color(0xFFB7791F);
      case 'principal':  return const Color(0xFF5C5FC6);
      case 'teacher':    return const Color(0xFF2F9E44);
      case 'student':    return const Color(0xFF1971C2);
      case 'parent':     return const Color(0xFFD6336C);
      default:           return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user    = ref.watch(userProvider);
    final cs      = Theme.of(context).colorScheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final txt     = Theme.of(context).textTheme;
    final badge   = _roleColor(user?.role);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ── EduAir logo ──────────────────────────────────────
                CircleAvatar(
                  radius: 34,
                  backgroundImage: const AssetImage(
                    'assets/images/eduair_logo.png',
                  ),
                ),

                const SizedBox(height: 36),

                // ── Status icon ──────────────────────────────────────
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.domain_disabled_rounded,
                    size: 38,
                    color: cs.primary,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Heading ──────────────────────────────────────────
                Text(
                  'No School Assigned',
                  style: txt.headlineSmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Your account hasn\'t been linked\nto a school yet.',
                  textAlign: TextAlign.center,
                  style: txt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 28),

                // ── What to do next card ─────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outline.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 17,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'What to do next',
                            style: txt.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _Step(
                        number: '1',
                        text: 'Contact your school administrator',
                        cs: cs,
                      ),
                      const SizedBox(height: 10),
                      _Step(
                        number: '2',
                        text:
                            'Ask them to link your account to the correct school',
                        cs: cs,
                      ),
                      const SizedBox(height: 10),
                      _Step(
                        number: '3',
                        text: 'Sign back in once your account is set up',
                        cs: cs,
                      ),
                    ],
                  ),
                ),

                // ── Logged-in user chip ──────────────────────────────
                if (user != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: cs.primary.withValues(alpha: 0.1),
                          child: Text(
                            user.initials,
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name + email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                style: txt.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user.email,
                                style: txt.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Role badge
                        if (user.role.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badge.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${user.role[0].toUpperCase()}'
                              '${user.role.substring(1)}',
                              style: TextStyle(
                                color: badge,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // ── Sign out ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _signOut(ref, context),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(
                        color: cs.error.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Numbered step row ────────────────────────────────────────────────────────
class _Step extends StatelessWidget {
  final String number;
  final String text;
  final ColorScheme cs;

  const _Step({
    required this.number,
    required this.text,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.65),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// Keep the old name as an alias so the router import doesn't break.
typedef SelectSchoolPage = NoSchoolPage;
