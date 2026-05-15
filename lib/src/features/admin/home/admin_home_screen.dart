import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/shared/widgets/app_greeting_header.dart';
import 'package:edu_air/src/features/admin/home/application/admin_home_provider.dart';
import 'package:edu_air/src/features/admin/home/widgets/stat_card.dart';
import 'package:edu_air/src/features/admin/home/widgets/action_card.dart';
import 'package:edu_air/src/features/admin/home/widgets/attendance_chart_card.dart';
import 'package:edu_air/src/features/admin/home/widgets/stats_card.dart';
import 'package:edu_air/src/features/admin/home/widgets/student_row.dart';
import 'package:edu_air/src/features/admin/home/widgets/audit_log_card.dart';
import 'package:edu_air/src/features/admin/home/widgets/attendance_trend_card.dart';
import 'package:edu_air/src/features/admin/home/widgets/notice_board_card.dart';
import 'package:shimmer/shimmer.dart';

class AdminHomeScreen extends ConsumerWidget {

  const AdminHomeScreen({super.key, required this.onSelectTab, required this.onOpenDrawer});

  final void Function(int index) onSelectTab;

  final VoidCallback onOpenDrawer;


 


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final homeAsync = ref.watch(adminHomeProvider);

    final name = (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName
        : 'Admin';

    final schoolName =
        homeAsync.whenOrNull(data: (d) => d.schoolName) ??
        (user?.schoolId != null
            ? 'School #${user!.schoolId}'
            : 'EduAir School');
    final adminId = user?.uid ?? '—';

    // whenOrNull returns the value only when the provider is in the 'data' state.
    // It returns null during loading and on error — the '??' provides the safe fallback.
    // We extract these here (not inside LayoutBuilder) because the card appears in
    // both the desktop row and the mobile column — extract once, use twice.
    final trendData     = homeAsync.whenOrNull(data: (d) => d.trendData)     ?? const [];
    final trendLabel    = homeAsync.whenOrNull(data: (d) => d.trendLabel)    ?? '';
    final totalStudents = homeAsync.whenOrNull(data: (d) => d.totalStudents) ?? 0;

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          primary: true,
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: homeAsync.when(
                  loading: () => const _StatRowSkeleton(),
                  error: (_, __) => const SizedBox(),
                  data: (d) => Row(
                    children: [
                      StatCard(
                        width: 140,
                        icon: Icons.people_outline,
                        label: 'Total Students',
                        value: d.totalStudents.toString(),
                        color: const Color(0xFFE8F2FF),
                        iconColor: const Color(0xFF4A7CFF),
                      ),
                      const SizedBox(width: 10),
                      StatCard(
                        width: 140,
                        icon: Icons.person_outline,
                        label: 'Today Present',
                        value: d.presentToday.toString(),
                        color: const Color(0xFFE6F6F3),
                        iconColor: const Color(0xFF2D9CDB),
                      ),
                      const SizedBox(width: 10),
                      StatCard(
                        width: 140,
                        icon: Icons.person_off_outlined,
                        label: 'Absent Today',
                        value: d.absentToday.toString(),
                        color: const Color(0xFFFDE9EC),
                        iconColor: const Color(0xFFE65D7B),
                      ),
                      const SizedBox(width: 10),
                      StatCard(
                        icon: Icons.schedule_outlined,
                        label: 'Late Today',
                        value: d.lateToday.toString(),
                        color: const Color(0xFFFFF8E1),
                        iconColor: const Color(0xFFF59E0B),
                        width: 140,
                      ),
                     
                      const SizedBox(width: 10),
                      StatCard(
                        width: 140,
                        icon: Icons.school_outlined,
                        label: 'Total Teachers',
                        value: d.totalTeachers.toString(),
                        color: const Color(0xFFF5EBFF),
                        iconColor: const Color(0xFF9B51E0),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Chart + Stats — side by side on desktop ───────────
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 700;
                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(flex: 3, child: AttendanceChartCard(trendData: trendData, totalStudents: totalStudents)),
                        const SizedBox(width: 16),
                        const Flexible(flex: 2, child: StatsCard()),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      AttendanceChartCard(trendData: trendData, totalStudents: totalStudents),
                      const SizedBox(height: 16),
                      const StatsCard(),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // ── Audit + Trend + Notice — 3 columns on desktop ─────
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 700;
                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Flexible(child: AuditLogCard()),
                        const SizedBox(width: 16),
                        Flexible(child: AttendanceTrendCard(trendData: trendData, trendLabel: trendLabel)),
                        const SizedBox(width: 16),
                        const Flexible(child: NoticeBoardCard()),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      const AuditLogCard(),
                      const SizedBox(height: 16),
                      const NoticeBoardCard(),
                      const SizedBox(height: 16),
                      AttendanceTrendCard(trendData: trendData, trendLabel: trendLabel),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // ── Quick Actions ────────────────────────────────────
              Text(
                'Quick Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 700 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: cols == 4 ? 2.2 : 1.6,
                    children: [
                      ActionCard(
                        icon: Icons.people_outline,
                        label: 'Manage Students',
                        color: const Color(0xFFE8F2FF),
                        iconColor: const Color(0xFF4A7CFF),
                        onTap: () => onSelectTab(1),
                      ),
                      ActionCard(
                        icon: Icons.badge_outlined,
                        label: 'Manage Staff',
                        color: const Color(0xFFF5EBFF),
                        iconColor: const Color(0xFF9B51E0),
                        onTap: () => onSelectTab(2),
                      ),
                      ActionCard(
                        icon: Icons.fact_check_outlined,
                        label: 'Attendance Report',
                        color: const Color(0xFFE6F6F3),
                        iconColor: const Color(0xFF2D9CDB),
                        onTap: () => onSelectTab(3),
                      ),
                      ActionCard(
                        icon: Icons.school_outlined,
                        label: 'School Info',
                        color: const Color(0xFFF8F2DC),
                        iconColor: const Color(0xFFB7791F),
                        onTap: () => onSelectTab(4),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // ── Recent Students ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Students',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: cs.onSurface),
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
              homeAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(
                  'Could not load students',
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                data: (d) => d.recentStudents.isEmpty
                    ? Text(
                        'No students yet',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      )
                    : Column(
                        children: d.recentStudents
                            .map(
                              (s) => StudentRow(
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
                              ),
                            )
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

class _StatRowSkeleton extends StatelessWidget {
  const _StatRowSkeleton();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        children: [
          Container(
            width: 140,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(width: 10),
          Container(
            width: 140,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(width: 10),
          Container(
            width: 140,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          SizedBox(width: 10),
          Container(
            width: 140,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(width: 10),
          Container(
            width: 140,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
