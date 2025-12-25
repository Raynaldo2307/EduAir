import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/teacher/profile/teacher_profile_edit.dart';
import 'package:edu_air/src/features/shared/widgets/profile_field.dart';
import 'package:edu_air/src/features/shared/widgets/profile_header.dart';

class TeacherProfilePage extends ConsumerWidget {
  const TeacherProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final theme = Theme.of(context);
    final dangerColor = theme.colorScheme.error;

    // If user is not loaded yet, show loader
    if (user == null) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    // ---------- Identity data for teacher --------------------
    final name = (user.displayName.trim().isNotEmpty)
        ? user.displayName
        : 'Teacher';

    // We don’t have a separate staffId yet, so reuse studentId field for now.
    final teacherId = user.studentId ?? '—';

    // Prefer dedicated teacherDepartment, fall back to gradeLevel for old docs.
    final department = user.teacherDepartment ?? user.gradeLevel ?? '—';

    final phone = user.phone.isNotEmpty ? user.phone : '—';
    final bio = user.bio ?? '—';

    return ColoredBox(
      color: AppTheme.surfaceVariant,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Page title ─────────────────────────────────────────────
                  Text(
                    'Profile',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ── Avatar + name + subtitle ──────────────────────────────
                  ProfileHeader(
                    name: name,
                    // Teacher-style subtitle
                    subtitle: 'Teacher • Dept: $department • ID: $teacherId',
                    photoUrl: user.photoUrl,
                    onEditProfile: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TeacherProfileEditPage(),
                        ),
                      );
                    },
                    onEditPhoto: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Change photo tapped (TODO)'),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Details card ───────────────────────────────────────────
                  ProfileDetailsCard(
                    fields: [
                      ProfileField(
                        label: 'Role',
                        value: user.role.isNotEmpty ? user.role : 'Teacher',
                      ),
                      ProfileField(label: 'Teacher ID', value: teacherId),
                      ProfileField(
                        label: 'Department / Subject',
                        value: department,
                      ),
                      ProfileField(label: 'Phone', value: phone),
                      ProfileField(label: 'Bio', value: bio),
                      // Later you can add:
                      // ProfileField(label: 'Email', value: user.email),
                      // ProfileField(label: 'Address', value: user.address ?? '—'),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Logout button ─────────────────────────────────────────
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
                          builder: (context) => AlertDialog(
                            title: const Text('Log out'),
                            content: const Text(
                              'Are you sure you want to log out?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Log Out'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          // Real sign-out using AuthService
                          await ref.read(authServiceProvider).signOut();

                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/onboarding', // or your sign-in route
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
