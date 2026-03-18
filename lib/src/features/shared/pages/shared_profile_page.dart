import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/shared/pages/shared_profile_edit_page.dart';
import 'package:edu_air/src/features/shared/widgets/profile_field.dart';
import 'package:edu_air/src/features/shared/widgets/profile_header.dart';

/// Role-aware profile view page.
///
/// Used by all roles — student, teacher, admin, principal.
/// The fields shown in [ProfileDetailsCard] adapt to the logged-in user's role.
class SharedProfilePage extends ConsumerWidget {
  const SharedProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dangerColor = cs.error;

    if (user == null) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    final role = user.role;
    final name = user.displayName.trim().isNotEmpty ? user.displayName : 'User';

    // ── Role-aware subtitle and fields ──────────────────────────────────────
    final String subtitle;
    final List<ProfileField> fields;

    switch (role) {
      case 'student':
        final studentId = user.studentId ?? '—';
        final grade = user.gradeLevel ?? '—';
        final className = user.className ?? '—';
        final dobText = user.dateOfBirth != null
            ? () {
                final d = user.dateOfBirth!;
                return '${d.day.toString().padLeft(2, '0')}-'
                    '${d.month.toString().padLeft(2, '0')}-'
                    '${d.year}';
              }()
            : '—';

        subtitle = 'Grade $grade • $className • ID: $studentId';
        fields = [
          ProfileField(label: 'Student ID', value: studentId),
          ProfileField(label: 'Class', value: className),
          ProfileField(label: 'Date of Birth', value: dobText),
          ProfileField(label: 'Gender', value: user.gender ?? '—'),
          ProfileField(
            label: 'Parent / Guardian',
            value: user.parentGuardianName ?? '—',
          ),
          ProfileField(
            label: 'Parent Contact',
            value: user.parentGuardianPhone ?? '—',
          ),
          ProfileField(
            label: 'Phone',
            value: user.phone.isNotEmpty ? user.phone : '—',
          ),
          ProfileField(label: 'Address', value: user.address ?? '—'),
        ];

      case 'teacher':
        final dept = user.teacherDepartment ?? user.gradeLevel ?? '—';
        final staffId = user.studentId ?? '—';
        subtitle = 'Teacher • $dept';
        fields = [
          ProfileField(label: 'Staff ID', value: staffId),
          ProfileField(label: 'Department', value: dept),
          ProfileField(
            label: 'Phone',
            value: user.phone.isNotEmpty ? user.phone : '—',
          ),
          ProfileField(label: 'Email', value: user.email),
          ProfileField(label: 'Bio', value: user.bio ?? '—'),
        ];

      case 'admin':
      case 'principal':
        final dept = user.teacherDepartment ?? '—';
        final displayRole =
            '${role[0].toUpperCase()}${role.substring(1)}';
        subtitle = displayRole;
        fields = [
          ProfileField(label: 'Role', value: displayRole),
          ProfileField(label: 'Department', value: dept),
          ProfileField(
            label: 'Phone',
            value: user.phone.isNotEmpty ? user.phone : '—',
          ),
          ProfileField(label: 'Email', value: user.email),
          ProfileField(label: 'Bio', value: user.bio ?? '—'),
        ];

      default:
        subtitle = role;
        fields = [ProfileField(label: 'Email', value: user.email)];
    }

    return ColoredBox(
      color: isDark ? AppTheme.darkBackground : AppTheme.surfaceVariant,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Page title ──────────────────────────────────────
                  Text(
                    'Profile',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Role badge ──────────────────────────────────────
                  _RoleBadge(role: role),
                  const SizedBox(height: 24),

                  // ── Avatar + name + subtitle ────────────────────────
                  ProfileHeader(
                    name: name,
                    subtitle: subtitle,
                    photoUrl: user.photoUrl,
                    onEditProfile: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SharedProfileEditPage(),
                        ),
                      );
                    },
                    onEditPhoto: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Change photo — coming soon'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Details card ────────────────────────────────────
                  ProfileDetailsCard(fields: fields),
                  const SizedBox(height: 32),

                  // ── Logout ──────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.logout, color: dangerColor),
                      label: Text(
                        'Log Out',
                        style: TextStyle(
                          color: dangerColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: dangerColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Log out'),
                            content: const Text(
                              'Are you sure you want to log out?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(true),
                                child: const Text('Log Out'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await ref.read(tokenStorageProvider).delete();
                          await ref.read(authServiceProvider).signOut();
                          ref.read(userProvider.notifier).state = null;
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/onboarding',
                              (route) => false,
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Role badge ────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (label, bg, fg) = switch (role) {
      'student'   => ('STUDENT',   const Color(0xFFD0EBFF), const Color(0xFF1971C2)),
      'teacher'   => ('TEACHER',   const Color(0xFFD3F9D8), const Color(0xFF2F9E44)),
      'admin'     => ('ADMIN',     const Color(0xFFF8F2DC), const Color(0xFFB7791F)),
      'principal' => ('PRINCIPAL', const Color(0xFFEDEDFF), const Color(0xFF5C5FC6)),
      _           => ('USER',      const Color(0xFFF1F3F5), const Color(0xFF495057)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? fg.withValues(alpha: 0.2) : bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
