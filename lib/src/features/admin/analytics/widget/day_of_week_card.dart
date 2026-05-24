import 'package:flutter/material.dart';

class DayOfWeekCard extends StatelessWidget {
  const DayOfWeekCard({super.key});

  // TODO: replace with real day-of-week averages from backend analytics endpoint
  static const _days = [
    _DayData('Mon', 0.98),
    _DayData('Tue', 0.96),
    _DayData('Wed', 0.97),
    _DayData('Thu', 0.92),
    _DayData('Fri', 0.70),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Find the worst day to highlight it
    final worstDay = _days.reduce((a, b) => a.value < b.value ? a : b);

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
              Text(
                'Attendance drops by 12% on ${_fullDayName(worstDay.label)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _days.map((day) {
                final isWorst = day.label == worstDay.label;
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
                              heightFactor: day.value,
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
                          day.label,
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
}

String _fullDayName(String short) {
  const map = {
    'Mon': 'Mondays',
    'Tue': 'Tuesdays',
    'Wed': 'Wednesdays',
    'Thu': 'Thursdays',
    'Fri': 'Fridays',
  };
  return map[short] ?? short;
}

class _DayData {
  final String label;
  final double value; // 0.0 – 1.0 attendance rate

  const _DayData(this.label, this.value);
}
