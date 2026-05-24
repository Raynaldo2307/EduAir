import 'package:flutter/material.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/admin/home/application/admin_home_provider.dart';

class AttendanceChartCard extends StatefulWidget {
  const AttendanceChartCard({
    super.key,
    required this.trendData,
    required this.totalStudents,
  });

  final List<AttendanceTrendPoint> trendData;
  final int totalStudents;

  @override
  State<AttendanceChartCard> createState() => _AttendanceChartCardState();
}

class _AttendanceChartCardState extends State<AttendanceChartCard> {
  int _selectedTab = 0; // 0=Attendance, 1=Enrollment, 2=Users

  static const _tabs = ['Attendance', 'Enrollment', 'Users'];

  // Each tab gets a distinct bar colour so the admin can tell them apart.
  static const _tabColors = [
    Color(0xFF0059BA), // Attendance — primary blue
    Color(0xFF2E7D32), // Enrollment — green
    Color(0xFF9B51E0), // Users — purple
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final week = widget.trendData.length >= 7
        ? widget.trendData.sublist(widget.trendData.length - 7)
        : widget.trendData;

    final barColor = _tabColors[_selectedTab];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: AppTheme.cardShadow(isDark: isDark, primary: cs.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tappable tab row
          Row(
            children: List.generate(_tabs.length, (i) {
              final active = _selectedTab == i;
              return Padding(
                padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 20 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  child: Column(
                    children: [
                      Text(
                        _tabs[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400,
                          color: active
                              ? _tabColors[i]
                              : cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 2,
                        width: active ? 40 : 0,
                        decoration: BoxDecoration(
                          color: _tabColors[i],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // Bar chart
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(week.length, (i) {
                      final point = week[i];
                      final barHeight = widget.totalStudents > 0
                          ? (point.totalPresent /
                                  widget.totalStudents *
                                  100)
                              .clamp(0, 100)
                              .toDouble()
                          : 0.0;
                      final dayLabel =
                          dayNames[DateTime.parse(point.date).weekday - 1];

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
        ],
      ),
    );
  }
}
