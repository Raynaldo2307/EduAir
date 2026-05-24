import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/features/admin/home/application/admin_home_provider.dart';
import 'package:edu_air/src/features/admin/analytics/application/admin_analytics_provider.dart';
import 'package:edu_air/src/features/admin/analytics/widget/admin_analytics_header.dart';
import 'package:edu_air/src/features/admin/analytics/widget/staff_consistency_card.dart';
import 'package:edu_air/src/features/admin/analytics/widget/day_of_week_card.dart';
import 'package:edu_air/src/features/admin/analytics/widget/export_sf4_button.dart';

class AdminAnalyticsPage extends ConsumerWidget {
  const AdminAnalyticsPage({
    super.key,
    required this.onBackToHome,
    this.onOpenDrawer,
  });

  final VoidCallback onBackToHome;
  final VoidCallback? onOpenDrawer;

  BoxDecoration _cardDecoration(ColorScheme cs) => BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final homeAsync      = ref.watch(adminHomeProvider);
    final analyticsAsync = ref.watch(adminAnalyticsProvider);

    final schoolName     = homeAsync.whenOrNull(data: (d) => d.schoolName) ?? 'EduAir School';
    final totalStudents  = homeAsync.whenOrNull(data: (d) => d.totalStudents) ?? 0;

    final chronicAbsentees = analyticsAsync.whenOrNull(data: (d) => d.chronicAbsentees) ?? 0;
    final avgAttendance    = analyticsAsync.whenOrNull(data: (d) => d.avgAttendance) ?? 0.0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminAnalyticsHeader(
                schoolName: schoolName,
                onOpenDrawer: onOpenDrawer,
              ),
              const SizedBox(height: 24),

              // ── Summary stat chips ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(cs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chronic Absentees',
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$chronicAbsentees',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: cs.error,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '(20%+)',
                                  style: TextStyle(fontSize: 12, color: cs.error),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(cs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Avg Attendance',
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${avgAttendance.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Attendance Trends — tappable 30D/90D/Term tabs ───────────
              _AttendanceTrendsCard(
                totalStudents: totalStudents,
                cs: cs,
              ),

              const SizedBox(height: 16),

              // ── Lowest Performing Classes ────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(cs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lowest Performing Classes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    analyticsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => Text(
                        'Could not load class data',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      data: (d) => d.classPerformance.isEmpty
                          ? Text(
                              'No class data yet',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            )
                          : Column(
                              children: d.classPerformance
                                  .asMap()
                                  .entries
                                  .map((e) => Padding(
                                        padding: EdgeInsets.only(
                                          top: e.key > 0 ? 10 : 0,
                                        ),
                                        child: _ClassRow(
                                          label:   e.value.className,
                                          value:   e.value.fraction,
                                          percent: '${e.value.attendanceRate.toStringAsFixed(1)}%',
                                          cs:      cs,
                                        ),
                                      ))
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Top 5 Absent / Late ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(cs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top 5 Absent/Late',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    analyticsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => Text(
                        'Could not load student data',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      data: (d) => d.topAbsent.isEmpty
                          ? Text(
                              'No absence data yet',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            )
                          : Column(
                              children: d.topAbsent
                                  .map((s) => Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: _TopAbsentStudent(
                                          firstName:      s.firstName,
                                          lastName:       s.lastName,
                                          className:      s.className,
                                          absencePercent: s.absencePercent,
                                          cs:             cs,
                                        ),
                                      ))
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Staff Consistency ────────────────────────────────────────
              analyticsAsync.when(
                loading: () => const SizedBox.shrink(),
                error:   (_, __) => const SizedBox.shrink(),
                data:    (d) => StaffConsistencyCard(staff: d.staffConsistency),
              ),

              const SizedBox(height: 16),

              // ── Day of Week ──────────────────────────────────────────────
              analyticsAsync.when(
                loading: () => const SizedBox.shrink(),
                error:   (_, __) => const SizedBox.shrink(),
                data:    (d) => DayOfWeekCard(days: d.dayOfWeek),
              ),

              const SizedBox(height: 24),

              const ExportSf4Button(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Attendance Trends Card ────────────────────────────────────────────────────
// ConsumerStatefulWidget so it can watch analyticsTrendsProvider with the
// selected days key and rebuild when the user taps a tab.
class _AttendanceTrendsCard extends ConsumerStatefulWidget {
  const _AttendanceTrendsCard({
    required this.totalStudents,
    required this.cs,
  });

  final int totalStudents;
  final ColorScheme cs;

  @override
  ConsumerState<_AttendanceTrendsCard> createState() =>
      _AttendanceTrendsCardState();
}

class _AttendanceTrendsCardState extends ConsumerState<_AttendanceTrendsCard> {
  int _selected = 0; // 0=30D, 1=90D, 2=Term

  static const _ranges    = ['30D', '90D', 'Term'];
  static const _daysKeys  = ['30',  '90',  'term'];

  static const _barColors = [
    Color(0xFF0059BA), // 30D — blue
    Color(0xFF2E7D32), // 90D — green
    Color(0xFF9B51E0), // Term — purple
  ];

  static const _dayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final cs       = widget.cs;
    final barColor = _barColors[_selected];
    final daysKey  = _daysKeys[_selected];

    final trendsAsync = ref.watch(analyticsTrendsProvider(daysKey));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Trends',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              Row(
                children: List.generate(_ranges.length, (i) {
                  final active = _selected == i;
                  return Padding(
                    padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? _barColors[i]
                              : cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _ranges[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: trendsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (_, __) => Center(
                child: Text(
                  'Could not load trend data',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
              data: (data) => data.isEmpty
                  ? Center(
                      child: Text(
                        'No trend data yet',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: List.generate(data.length, (i) {
                        final point = data[i];
                        final barHeight = widget.totalStudents > 0
                            ? (point.totalPresent /
                                    widget.totalStudents *
                                    130)
                                .clamp(0, 130)
                                .toDouble()
                            : 0.0;
                        final dayLabel = _dayNames[
                            DateTime.parse(point.date).weekday - 1];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                width: 28,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                dayLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LegendDot(color: barColor, label: 'Students', cs: cs),
              const SizedBox(width: 16),
              _LegendDot(
                color: const Color(0xFF2D9CDB),
                label: 'Staff',
                cs: cs,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Support widgets ──────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, this.cs});

  final Color color;
  final String label;
  final ColorScheme? cs;

  @override
  Widget build(BuildContext context) {
    final scheme = cs ?? Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({
    required this.label,
    required this.value,
    required this.percent,
    required this.cs,
  });

  final String label;
  final double value;   // 0.0 – 1.0 fraction
  final String percent;
  final ColorScheme cs;

  Color _severityColor() {
    if (value < 0.80) return cs.error;
    if (value < 0.90) return const Color(0xFFB7791F);
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _severityColor();
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const Spacer(),
            Text(
              percent,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          color: color,
          backgroundColor: cs.surfaceContainerLow,
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _TopAbsentStudent extends StatelessWidget {
  const _TopAbsentStudent({
    required this.className,
    required this.absencePercent,
    required this.firstName,
    required this.lastName,
    required this.cs,
  });

  final String firstName;
  final String lastName;
  final String className;
  final double absencePercent;
  final ColorScheme cs;

  Color _chipColor() {
    if (absencePercent >= 30) return cs.error;
    if (absencePercent >= 20) return const Color(0xFFB7791F);
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final initials  = '${firstName.isNotEmpty ? firstName[0].toUpperCase() : '?'}'
                      '${lastName.isNotEmpty  ? lastName[0].toUpperCase()  : '?'}';
    final chipColor = _chipColor();
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: cs.secondaryContainer,
          child: Text(
            initials,
            style: TextStyle(
              color: cs.onSecondaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$firstName $lastName',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              Text(
                className.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.6,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: chipColor.withValues(alpha: 0.35)),
          ),
          child: Text(
            '${absencePercent.toInt()}% absent',
            style: TextStyle(
              color: chipColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
