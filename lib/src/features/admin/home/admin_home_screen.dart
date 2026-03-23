import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/shared/widgets/app_greeting_header.dart';
import 'package:edu_air/src/shared/widgets/user_avatar.dart';
import 'package:edu_air/src/features/admin/home/application/admin_home_provider.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key, required this.onSelectTab});

  final void Function(int index) onSelectTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(userProvider);
    final homeAsync = ref.watch(adminHomeProvider);

    final name = (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName
        : 'Admin';

    // School name comes from the user profile (set during login).
    // TODO: replace with GET /api/schools/me for full school details.
    final schoolName = user?.schoolId != null ? 'School #${user!.schoolId}' : 'EduAir School';
    final adminId    = user?.uid ?? '—';

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              AppGreetingHeader(
                name: name,
                id: adminId,
                initials: user?.initials ?? 'U',
                subtitle: schoolName,
                avatarUrl: user?.photoUrl,
              ),

              const SizedBox(height: 20),

              // ── Stats row ────────────────────────────────────────
              Row(
                children: [
                  _StatCard(
                    icon: Icons.people_outline,
                    label: 'Total Students',
                    value: homeAsync.when(
                      data: (d) => d.totalStudents.toString(),
                      loading: () => '—',
                      error: (_, __) => '?',
                    ),
                    color: const Color(0xFFE8F2FF),
                    iconColor: const Color(0xFF4A7CFF),
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.person_outline,
                    label: 'Today Present',
                    value: '—', // TODO: GET /api/attendance/stats?date=today
                    color: const Color(0xFFE6F6F3),
                    iconColor: const Color(0xFF2D9CDB),
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.person_off_outlined,
                    label: 'Absent Today',
                    value: '—', // TODO: GET /api/attendance/stats?date=today
                    color: const Color(0xFFFDE9EC),
                    iconColor: const Color(0xFFE65D7B),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Quick Actions title ──────────────────────────────
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: cs.onSurface,
                    ),
              ),

              const SizedBox(height: 14),

              // ── Quick Actions 2x2 grid ───────────────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _ActionCard(
                    icon: Icons.people_outline,
                    label: 'Manage Students',
                    color: const Color(0xFFE8F2FF),
                    iconColor: const Color(0xFF4A7CFF),
                    onTap: () => onSelectTab(1),
                  ),
                  _ActionCard(
                    icon: Icons.badge_outlined,
                    label: 'Manage Staff',
                    color: const Color(0xFFF5EBFF),
                    iconColor: const Color(0xFF9B51E0),
                    onTap: () => onSelectTab(2),
                  ),
                  _ActionCard(
                    icon: Icons.fact_check_outlined,
                    label: 'Attendance Report',
                    color: const Color(0xFFE6F6F3),
                    iconColor: const Color(0xFF2D9CDB),
                    onTap: () => onSelectTab(3),
                  ),
                  _ActionCard(
                    icon: Icons.school_outlined,
                    label: 'School Info',
                    color: const Color(0xFFF8F2DC),
                    iconColor: const Color(0xFFB7791F),
                    onTap: () => onSelectTab(4),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Recent Students header ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Students',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: cs.onSurface,
                        ),
                  ),
                  TextButton(
                    onPressed: () => onSelectTab(1),
                    child: Text(
                      'View all',
                      style: TextStyle(color: cs.primary),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Recent Students list ─────────────────────────────
              homeAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Could not load students',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
                data: (d) => d.recentStudents.isEmpty
                    ? Text('No students yet',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)))
                    : Column(
                        children: d.recentStudents
                            .map((s) => _StudentRow(
                                  initials: s.initials,
                                  name: s.displayName,
                                  subtitle: [
                                    if (s.className?.isNotEmpty == true)
                                      s.className!
                                    else if (s.gradeLevel?.isNotEmpty == true)
                                      s.gradeLevel!,
                                    if (s.currentShift != null)
                                      _formatShift(s.currentShift!),
                                  ].join(' · '),
                                ))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatShift(String shift) {
  switch (shift) {
    case 'morning':
      return 'Morning';
    case 'afternoon':
      return 'Afternoon';
    case 'whole_day':
      return 'Whole Day';
    default:
      return shift;
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? iconColor.withValues(alpha: 0.2) : color,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Card ──────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? iconColor.withValues(alpha: 0.2) : color,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.3 : 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isDark ? Colors.white : iconColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Student Row ──────────────────────────────────────────────────────────────

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.initials,
    required this.name,
    required this.subtitle,
  });

  final String initials;
  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: Row(
        children: [
          UserAvatar(initials: initials, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
