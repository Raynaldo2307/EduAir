import 'package:flutter/material.dart';
import 'package:edu_air/src/features/admin/analytics/application/admin_analytics_provider.dart';

class DayOfWeekCard extends StatelessWidget {
  const DayOfWeekCard({super.key, required this.days});

  final List<DayOfWeekStat> days;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (days.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _decoration(cs),
        child: Text(
          'Not enough data yet',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    final worstDay = days.reduce((a, b) => a.attendanceRate < b.attendanceRate ? a : b);
    final avgRate  = days.fold(0.0, (sum, d) => sum + d.attendanceRate) / days.length;
    final drop     = (avgRate - worstDay.attendanceRate).clamp(0.0, 100.0).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoration(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Day-of-Week Attendance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: cs.error),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Attendance drops by $drop% on ${worstDay.dayName}s',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final isWorst = day.dayName == worstDay.dayName;
                final barColor = isWorst ? cs.error : cs.primary;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: day.fraction,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          day.shortName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isWorst ? FontWeight.w700 : FontWeight.w400,
                            color: isWorst ? cs.error : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _decoration(ColorScheme cs) => BoxDecoration(
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
}
