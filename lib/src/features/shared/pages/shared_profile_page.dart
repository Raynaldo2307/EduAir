import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/models/app_user.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';
import 'package:edu_air/src/features/shared/pages/shared_profile_edit_page.dart';
import 'package:edu_air/src/features/shared/widgets/profile_field.dart';

/// Role-aware profile view page.
///
/// Works for all roles: student, teacher, admin, principal, parent.
/// - Scaffold with back button (navigates back to Settings).
/// - Hero card: UserAvatar (initials or photo), name, role badge, subtitle.
/// - Stats row: 3 key data points per role.
/// - Info card: role-specific fields.
/// - No logout button — logout lives in Settings to avoid duplication.
class SharedProfilePage extends ConsumerWidget {
  const SharedProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = user.displayName.trim().isNotEmpty ? user.displayName : 'User';

    // ── Role-aware subtitle + fields ────────────────────────────────────────
    final (String subtitle, List<ProfileField> fields) = _buildRoleContent(user);

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light  // white icons on dark bg
            : SystemUiOverlayStyle.dark,  // black icons on light bg
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: cs.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: AppTheme.primaryColor,
              size: 22,
            ),
            tooltip: 'Edit Profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SharedProfileEditPage(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero card ──────────────────────────────────────────────
              _HeroCard(
                user: user,
                name: name,
                subtitle: subtitle,
                isDark: isDark,
                onEditPhoto: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Change photo — coming soon')),
                ),
              ),

              const SizedBox(height: 16),

              // ── Stats row (role-aware) ─────────────────────────────────
              _StatsRow(user: user, isDark: isDark),

              const SizedBox(height: 20),

              // ── Info section ───────────────────────────────────────────
              _SectionLabel('INFORMATION'),
              const SizedBox(height: 8),
              ProfileDetailsCard(fields: fields),
            ],
          ),
        ),
      ),
    );
  }

  (String subtitle, List<ProfileField> fields) _buildRoleContent(
    AppUser user,
  ) {
    switch (user.role) {
      case 'student':
        final grade = user.gradeLevel ?? '—';
        final cls = user.className ?? '—';
        final dob = user.dateOfBirth != null
            ? '${user.dateOfBirth!.day.toString().padLeft(2, '0')}-'
                '${user.dateOfBirth!.month.toString().padLeft(2, '0')}-'
                '${user.dateOfBirth!.year}'
            : '—';
        final parts = <String>[];
        if (user.gradeLevel != null) parts.add('Grade ${user.gradeLevel}');
        if (user.className != null) parts.add(user.className!);
        return (
          parts.join(' • '),
          [
            ProfileField(label: 'Student ID', value: user.studentId ?? '—'),
            ProfileField(label: 'Class', value: cls),
            ProfileField(label: 'Grade', value: grade),
            ProfileField(label: 'Date of Birth', value: dob),
            ProfileField(
              label: 'Gender',
              value: user.sex ?? user.gender ?? '—',
            ),
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
          ],
        );

      case 'teacher':
        final dept = user.teacherDepartment ?? '—';
        final homeroom = user.homeroomClassName ?? '—';
        return (
          dept != '—' ? dept : 'Teacher',
          [
            ProfileField(label: 'Staff ID', value: user.studentId ?? '—'),
            ProfileField(label: 'Department', value: dept),
            ProfileField(label: 'Homeroom', value: homeroom),
            ProfileField(
              label: 'Phone',
              value: user.phone.isNotEmpty ? user.phone : '—',
            ),
            ProfileField(label: 'Email', value: user.email),
            ProfileField(label: 'Bio', value: user.bio ?? '—'),
          ],
        );

      case 'admin':
      case 'principal':
        final displayRole =
            user.role[0].toUpperCase() + user.role.substring(1);
        final dept = user.teacherDepartment ?? '—';
        return (
          displayRole,
          [
            ProfileField(label: 'Role', value: displayRole),
            ProfileField(label: 'Department', value: dept),
            ProfileField(
              label: 'Phone',
              value: user.phone.isNotEmpty ? user.phone : '—',
            ),
            ProfileField(label: 'Email', value: user.email),
            ProfileField(label: 'Bio', value: user.bio ?? '—'),
          ],
        );

      case 'parent':
        final childCount = user.childrenIds?.length ?? 0;
        return (
          'Parent',
          [
            ProfileField(
              label: 'Phone',
              value: user.phone.isNotEmpty ? user.phone : '—',
            ),
            ProfileField(label: 'Email', value: user.email),
            ProfileField(label: 'Address', value: user.address ?? '—'),
            ProfileField(
              label: 'Children',
              value: childCount > 0 ? '$childCount registered' : '—',
            ),
          ],
        );

      default:
        return (user.role, [ProfileField(label: 'Email', value: user.email)]);
    }
  }
}

// ── Hero card ──────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.user,
    required this.name,
    required this.subtitle,
    required this.isDark,
    required this.onEditPhoto,
  });

  final AppUser user;
  final String name;
  final String subtitle;
  final bool isDark;
  final VoidCallback onEditPhoto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar + camera button
          Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(
                initials: user.initials,
                photoUrl: user.photoUrl,
                radius: 48,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: GestureDetector(
                  onTap: onEditPhoto,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // Role badge
          _RoleBadge(role: user.role),

          // Subtitle (dept / grade+class / etc.)
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stats row ──────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user, required this.isDark});

  final AppUser user;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final stats = _statsFor(user);
    if (stats.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          Expanded(
            child: _StatChip(
              label: stats[i].$1,
              value: stats[i].$2,
              isDark: isDark,
            ),
          ),
          if (i < stats.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  List<(String label, String value)> _statsFor(AppUser user) {
    switch (user.role) {
      case 'student':
        return [
          ('Grade', user.gradeLevel ?? '—'),
          ('Class', user.className ?? '—'),
          ('Shift', _formatShift(user.currentShift)),
        ];
      case 'teacher':
        final subjectCount = user.subjectAssignments?.length ?? 0;
        return [
          ('Homeroom', user.homeroomClassName ?? '—'),
          ('Dept', user.teacherDepartment ?? '—'),
          ('Subjects', '$subjectCount'),
        ];
      case 'admin':
      case 'principal':
        return [
          ('Role', user.role[0].toUpperCase() + user.role.substring(1)),
          ('School', user.schoolId ?? '—'),
        ];
      case 'parent':
        final count = user.childrenIds?.length ?? 0;
        return [('Children', '$count')];
      default:
        return [];
    }
  }

  String _formatShift(String? shift) {
    switch (shift) {
      case 'morning':
        return 'Morning';
      case 'afternoon':
        return 'Afternoon';
      case 'whole_day':
        return 'Full Day';
      default:
        return '—';
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role badge ─────────────────────────────────────────────────────────────────

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
      'parent'    => ('PARENT',    const Color(0xFFFFECF0), const Color(0xFFD6336C)),
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
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? fg.withValues(alpha: 0.9) : fg,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        letterSpacing: 0.8,
      ),
    );
  }
}
