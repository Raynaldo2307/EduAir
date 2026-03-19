// lib/src/features/shell/select_role.dart
//
// SelectRolePage — shown when a logged-in user has no role assigned.
//
// In normal flow this screen is never reached:
//   - Email/password users always have a role set at account creation (Node API).
//   - Google Sign-In users default to 'student' in auth_services.dart.
//
// If a user lands here it means their account is incomplete.
// We let them pick a role for the current session (updates userProvider in memory).
// Persistent role assignment must be done by an admin on the server.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';

class SelectRolePage extends ConsumerStatefulWidget {
  const SelectRolePage({super.key});

  @override
  ConsumerState<SelectRolePage> createState() => _SelectRolePageState();
}

class _SelectRolePageState extends ConsumerState<SelectRolePage> {
  String? _selectedRole;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _continueWithRole() {
    if (_selectedRole == null) {
      _showSnack('Please select a role to continue.');
      return;
    }

    final currentUser = ref.read(userProvider);
    if (currentUser == null) {
      _showSnack('Session expired. Please sign in again.');
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/onboarding',
        (_) => false,
      );
      return;
    }

    // Update in-memory state only.
    // The server-side role must be set by an admin — this is temporary.
    final updated = currentUser.copyWith(role: _selectedRole!);
    ref.read(userProvider.notifier).state = updated;

    final schoolId = updated.schoolId;
    if (schoolId == null || schoolId.isEmpty) {
      Navigator.of(context).pushNamedAndRemoveUntil('/noSchool', (_) => false);
      return;
    }

    final route = (_selectedRole == 'teacher' ||
            _selectedRole == 'admin' ||
            _selectedRole == 'principal')
        ? '/teacherHome'
        : '/studentHome';

    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user   = ref.watch(userProvider);
    final cs     = Theme.of(context).colorScheme;
    final txt    = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name   = user?.firstName.isNotEmpty == true
        ? user!.firstName
        : 'there';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: Text(
            'Select Role',
            style: txt.titleLarge?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: cs.surface,
          systemOverlayStyle: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              Text(
                'Welcome, $name',
                style: txt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'How will you use EduAir?',
                textAlign: TextAlign.center,
                style: txt.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),

              const SizedBox(height: 36),

              // Role cards
              Row(
                children: [
                  _RoleCard(
                    label: 'Student',
                    value: 'student',
                    icon: Icons.school_rounded,
                    selected: _selectedRole == 'student',
                    cs: cs,
                    onTap: () => setState(() => _selectedRole = 'student'),
                  ),
                  const SizedBox(width: 16),
                  _RoleCard(
                    label: 'Teacher',
                    value: 'teacher',
                    icon: Icons.person_rounded,
                    selected: _selectedRole == 'teacher',
                    cs: cs,
                    onTap: () => setState(() => _selectedRole = 'teacher'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Info note
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: cs.outline.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your permanent role is set by your school administrator.',
                        style: txt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedRole != null ? _continueWithRole : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    disabledBackgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Role card ────────────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool selected;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.selected,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 140,
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.08)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? cs.primary : cs.outline.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 44,
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
