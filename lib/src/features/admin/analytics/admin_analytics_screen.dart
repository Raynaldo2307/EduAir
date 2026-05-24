import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/features/admin/home/application/admin_home_provider.dart';
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
    final homeAsync = ref.watch(adminHomeProvider);

    final schoolName =
        homeAsync.whenOrNull(data: (d) => d.schoolName) ?? 'EduAir School';

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

              // Stat chips row
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
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '14',
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.error,
                                  ),
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
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '94.2%',
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

              // Attendance Trends card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(cs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Attendance\nTrends',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            _TabChip(label: '30D', selected: true, cs: cs),
                            const SizedBox(width: 4),
                            _TabChip(label: '90D', selected: false, cs: cs),
                            const SizedBox(width: 4),
                            _TabChip(label: 'Term', selected: false, cs: cs),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Bar chart coming soon',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _LegendDot(
                          color: cs.primary,
                          label: 'Students',
                          cs: cs,
                        ),
                        const SizedBox(width: 16),
                        const _LegendDot(
                          color: Color(0xFF2D9CDB),
                          label: 'Staff',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Lowest performing classes
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
                    _ClassRow(
                      label: 'Class 9B',
                      value: 0.645,
                      percent: '64.5%',
                      barColor: cs.error,
                      percentColor: cs.error,
                      cs: cs,
                    ),
                    const SizedBox(height: 10),
                    _ClassRow(
                      label: 'Class 11C',
                      value: 0.721,
                      percent: '72.1%',
                      barColor: const Color(0xFFB7791F),
                      percentColor: const Color(0xFFB7791F),
                      cs: cs,
                    ),
                    const SizedBox(height: 10),
                    _ClassRow(
                      label: 'Class 7A',
                      value: 0.748,
                      percent: '74.8%',
                      barColor: const Color(0xFFB7791F),
                      percentColor: const Color(0xFFB7791F),
                      cs: cs,
                    ),
                    const SizedBox(height: 10),
                    _ClassRow(
                      label: 'Class 10D',
                      value: 0.785,
                      percent: '78.5%',
                      barColor: cs.primary,
                      percentColor: cs.primary,
                      cs: cs,
                    ),
                    const SizedBox(height: 10),
                    _ClassRow(
                      label: 'Class 8F',
                      value: 0.822,
                      percent: '82.2%',
                      barColor: cs.primary,
                      percentColor: cs.primary,
                      cs: cs,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Top 5 Absent/Late
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
                    ...homeAsync.whenOrNull(
                          data: (d) => d.topAbsent
                              .map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _TopAbsentStudent(
                                    firstName: s.firstName,
                                    lastName: s.lastName,
                                    className: s.className,
                                    absencePercent: s.absencePercent,
                                    cs: cs,
                                  ),
                                ),
                              )
                              .toList(),
                        ) ??
                        [],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Staff Consistency — which staff members are showing up reliably
              homeAsync.when(
                data: (d) => StaffConsistencyCard(staff: d.staffConsistency),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // Day-of-Week — which day students miss school the most
              const DayOfWeekCard(),

              const SizedBox(height: 24),

              // Export SF4 — generate Ministry of Education attendance report
              const ExportSf4Button(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.cs,
  });

  final String label;
  final bool selected;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? cs.primary : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? cs.onPrimary : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

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
        Text(
          label,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({
    required this.label,
    required this.value,
    required this.percent,
    required this.barColor,
    required this.percentColor,
    required this.cs,
  });

  final String label;
  final double value;
  final String percent;
  final Color barColor;
  final Color percentColor;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const Spacer(),
            Text(
              percent,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: percentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          color: barColor,
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

  @override
  Widget build(BuildContext context) {
    final initials =
        '${firstName[0].toUpperCase()}${lastName[0].toUpperCase()}';
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cs.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${absencePercent.toInt()}% Abs.',
            style: TextStyle(
              color: cs.error,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
