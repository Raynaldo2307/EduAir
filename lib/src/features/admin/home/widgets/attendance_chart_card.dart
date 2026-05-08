import 'package:flutter/material.dart';
import 'package:edu_air/src/core/app_theme.dart';

class AttendanceChartCard extends StatelessWidget {
  const AttendanceChartCard({super.key});

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _values = [0.85, 0.60, 0.90, 0.45, 0.75, 0.30, 0.55];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_days.length, (i) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 28,
                      height: 100 * _values[i],
                      decoration: BoxDecoration(
                        color: const Color(0xFF0059BA),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _days[i],
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
