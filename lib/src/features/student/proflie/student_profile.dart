import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/student/proflie/widgets/profile_field.dart';
import 'package:edu_air/src/features/student/proflie/widgets/profile_header.dart';

class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    final name = (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName
        : 'Dev Cooper';

    final studentId = user?.studentId ?? 'S87456314';
    final grade = user?.gradeLevel ?? '7th';
    final section = 'B';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Page title ───────────────────────────────────────────────
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // ── Avatar + name + subtitle ────────────────────────────────
            ProfileHeader(
              name: name,
              subtitle: '$grade Grade $section Section (SID: $studentId)',
              photoUrl: user?.photoUrl,
            ),

            const SizedBox(height: 24),

            // ── Details card ────────────────────────────────────────────
            ProfileDetailsCard(
              fields: const [
                ProfileField(label: 'Date Of Birth', value: '30 Nov 2011'),
                ProfileField(label: 'Father Name', value: 'Ronald Cooper'),
                ProfileField(label: 'Gender', value: 'Male'),
                ProfileField(label: 'Class', value: '7th / B'),
                ProfileField(label: 'Roll Number', value: '04'),
                ProfileField(label: 'Phone Number', value: '(480) 555-0103'),
                ProfileField(
                  label: 'Address',
                  value: '1901 Thornridge Cir. Shiloh, Hawaii 81063',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Logout ──────────────────────────────────────────────────
            TextButton(
              onPressed: () {
                // TODO: wire this to your auth sign-out logic
                // e.g. ref.read(authServiceProvider).signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Log out tapped (TODO)')),
                );
              },
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
