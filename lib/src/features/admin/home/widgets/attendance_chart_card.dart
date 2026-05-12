import 'package:flutter/material.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/admin/home/application/admin_home_provider.dart';

// Bar chart showing attendance for the last 7 school days.
// Each bar = one day. Height = fraction of enrolled students who showed up.
class AttendanceChartCard extends StatelessWidget {
  const AttendanceChartCard({
    super.key,
    required this.trendData,     // 30-day list from adminHomeProvider
    required this.totalStudents, // total enrolled — denominator for bar height
  });

  final List<AttendanceTrendPoint> trendData;
  final int totalStudents;

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // weekday returns 1 (Mon) to 7 (Sun). Subtract 1 → 0-based index for this list.
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Slice last 7 entries from the 30-day trend list.
    // If the school has fewer than 7 days of data, use whatever exists.
    final week = trendData.length >= 7
        ? trendData.sublist(trendData.length - 7)
        : trendData;

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ChartTab(label: 'Attendance', active: true),
              const SizedBox(width: 16),
              _ChartTab(label: 'Enrollment', active: false),
              const SizedBox(width: 16),
              _ChartTab(label: 'Users', active: false),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: week.isEmpty
                ? Center(
                    child: Text(
                      'No attendance data yet',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(week.length, (i) {
                      // 'point' is Ray's variable — week[i] is the item at this index.
                      // List.generate gives us i (the index). We use it to pull the item.
                      final point = week[i];

                      // Formula Ray derived: (showed up ÷ total enrolled) × 100 = bar height in px.
                      // clamp(0, 100) prevents bar from overflowing if data is unusual.
                      // totalStudents guard prevents divide-by-zero crash.
                      final barHeight = totalStudents > 0
                          ? (point.totalPresent / totalStudents * 100).clamp(0, 100).toDouble()
                          : 0.0;

                      // Parse date string → DateTime → weekday number → list index → day name.
                      final dayLabel = dayNames[DateTime.parse(point.date).weekday - 1];

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 28,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0059BA),
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
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChartTab extends StatelessWidget {
  const _ChartTab({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? cs.primary : cs.onSurface.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 4),
        if (active)
          Container(
            height: 2,
            width: 40,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}
