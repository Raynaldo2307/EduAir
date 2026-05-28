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
import 'package:edu_air/src/features/admin/students/admin_student_edit_page.dart';
import 'package:edu_air/src/shared/widgets/student_detail_sheet.dart';
import 'package:shimmer/shimmer.dart';

class AdminHomeScreen extends ConsumerWidget {

  const AdminHomeScreen({super.key, required this.onSelectTab, this.onOpenDrawer});

  final void Function(int index) onSelectTab;

  final VoidCallback? onOpenDrawer;


 


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
    final trendData      = homeAsync.whenOrNull(data: (d) => d.trendData)        ?? const [];
    final trendLabel     = homeAsync.whenOrNull(data: (d) => d.trendLabel)       ?? '';
    final totalStudents  = homeAsync.whenOrNull(data: (d) => d.totalStudents)    ?? 0;
    final auditLogs      = homeAsync.whenOrNull(data: (d) => d.recentAuditLogs)  ?? const [];

    // Week-over-week deltas — null when < 7 days of history available.
    final presentTrend = homeAsync.whenOrNull(
      data: (d) => _weekDelta(d.presentToday, trendData, 'present'),
    );
    final absentTrend = homeAsync.whenOrNull(
      data: (d) => _weekDelta(d.absentToday, trendData, 'absent'),
    );
    final lateTrend = homeAsync.whenOrNull(
      data: (d) => _weekDelta(d.lateToday, trendData, 'late'),
    );

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
              // Desktop: all cards Expanded across the full width — no scroll.
              // Mobile: fixed 140px cards in horizontal scroll + right-edge fade.
              // Adding a new stat card in the future = one StatCard entry here, nothing else changes.
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 700;

                  if (homeAsync.isLoading) {
                    return const SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _StatRowSkeleton(),
                    );
                  }
                  if (homeAsync.hasError) return const SizedBox();

                  final d = homeAsync.asData!.value;

                  final presentUp = presentTrend != null
                      ? d.presentToday >= (trendData.length >= 7 ? trendData[trendData.length - 7].totalPresent : d.presentToday)
                      : null;
                  final absentUp = absentTrend != null
                      ? d.absentToday <= (trendData.length >= 7 ? trendData[trendData.length - 7].absentCount : d.absentToday)
                      : null;
                  final lateUp = lateTrend != null
                      ? d.lateToday <= (trendData.length >= 7 ? trendData[trendData.length - 7].lateCount : d.lateToday)
                      : null;

                  final statCards = [
                    StatCard(
                      width: isDesktop ? null : 140,
                      icon: Icons.people_outline,
                      label: 'Total Students',
                      value: d.totalStudents.toString(),
                      color: const Color(0xFFE8F2FF),
                      iconColor: const Color(0xFF4A7CFF),
                    ),
                    StatCard(
                      width: isDesktop ? null : 140,
                      icon: Icons.person_outline,
                      label: 'Today Present',
                      value: d.presentToday.toString(),
                      color: const Color(0xFFE6F6F3),
                      iconColor: const Color(0xFF2D9CDB),
                      trend: presentTrend,
                      trendUp: presentUp,
                    ),
                    StatCard(
                      width: isDesktop ? null : 140,
                      icon: Icons.person_off_outlined,
                      label: 'Absent Today',
                      value: d.absentToday.toString(),
                      color: const Color(0xFFFDE9EC),
                      iconColor: const Color(0xFFE65D7B),
                      trend: absentTrend,
                      trendUp: absentUp,
                    ),
                    StatCard(
                      width: isDesktop ? null : 140,
                      icon: Icons.schedule_outlined,
                      label: 'Late Today',
                      value: d.lateToday.toString(),
                      color: const Color(0xFFFFF8E1),
                      iconColor: const Color(0xFFF59E0B),
                      trend: lateTrend,
                      trendUp: lateUp,
                    ),
                    StatCard(
                      width: isDesktop ? null : 140,
                      icon: Icons.school_outlined,
                      label: 'Total Teachers',
                      value: d.totalTeachers.toString(),
                      color: const Color(0xFFF5EBFF),
                      iconColor: const Color(0xFF9B51E0),
                    ),
                  ];

                  if (isDesktop) {
                    return Row(
                      children: [
                        for (int i = 0; i < statCards.length; i++) ...[
                          Expanded(child: statCards[i]),
                          if (i < statCards.length - 1) const SizedBox(width: 10),
                        ],
                      ],
                    );
                  }

                  return Stack(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (int i = 0; i < statCards.length; i++) ...[
                              statCards[i],
                              if (i < statCards.length - 1) const SizedBox(width: 10),
                            ],
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0, top: 0, bottom: 0,
                        child: IgnorePointer(
                          child: Container(
                            width: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  cs.surface.withValues(alpha: 0.0),
                                  cs.surface.withValues(alpha: 0.85),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
                        Flexible(child: AuditLogCard(logs: auditLogs)),
                        const SizedBox(width: 16),
                        Flexible(child: AttendanceTrendCard(trendData: trendData, trendLabel: trendLabel)),
                        const SizedBox(width: 16),
                        const Flexible(child: NoticeBoardCard()),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      AuditLogCard(logs: auditLogs),
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
                'QUICK ACTIONS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: cs.onSurface.withValues(alpha: 0.65),
                ),
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
                    'RECENT STUDENTS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: cs.onSurface.withValues(alpha: 0.55),
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
                                shift: s.currentShift,
                                subtitle: s.className?.isNotEmpty == true
                                    ? s.className!
                                    : (s.gradeLevel?.isNotEmpty == true
                                        ? 'Grade ${s.gradeLevel}'
                                        : '—'),
                                onTap: () => showStudentDetail(
                                  context,
                                  s,
                                  isAdmin: true,
                                  onEdit: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AdminStudentEditPage(student: s),
                                      ),
                                    );
                                  },
                                ),
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


// Compares today's value against the same day last week using trendData.
// Returns null when there aren't 7 days of history yet.
String? _weekDelta(int todayValue, List<AttendanceTrendPoint> trend, String field) {
  if (trend.length < 7) return null;
  final weekAgo = trend[trend.length - 7];
  final weekAgoValue = switch (field) {
    'present' => weekAgo.totalPresent,
    'late'    => weekAgo.lateCount,
    'absent'  => weekAgo.absentCount,
    _         => 0,
  };
  final delta = todayValue - weekAgoValue;
  if (delta == 0) return 'Same as last week';
  final sign = delta > 0 ? '+' : '';
  return '$sign$delta vs last week';
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
