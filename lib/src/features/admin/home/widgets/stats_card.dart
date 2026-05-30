import 'package:flutter/material.dart';
import 'package:edu_air/src/core/app_theme.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.attendanceRate,
    required this.absenceRate,
    this.weekAvgRate,
  });

  // presentToday / totalStudents — 0.0 to 1.0
  final double attendanceRate;
  // absentToday / totalStudents — 0.0 to 1.0 (lower is better)
  final double absenceRate;
  // Average of last 7 trend days / totalStudents — null when < 7 days of history
  final double? weekAvgRate;

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: AppTheme.cardShadow(isDark: isDark, primary: cs.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ATTENDANCE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 16),
          _StatBar(
            icon: Icons.check_circle_outline,
            label: 'Today\'s Attendance',
            value: attendanceRate.clamp(0.0, 1.0),
            color: _attendanceColor(attendanceRate),
          ),
          const SizedBox(height: 14),
          weekAvgRate != null
              ? _StatBar(
                  icon: Icons.calendar_month_outlined,
                  label: '7-Day Average',
                  value: weekAvgRate!.clamp(0.0, 1.0),
                  color: _attendanceColor(weekAvgRate!),
                )
              : _NoDataRow(
                  icon: Icons.calendar_month_outlined,
                  label: '7-Day Average',
                  cs: cs,
                ),
          const SizedBox(height: 14),
          _StatBar(
            icon: Icons.person_off_outlined,
            label: 'Absence Rate',
            value: absenceRate.clamp(0.0, 1.0),
            color: _absenceColor(absenceRate),
          ),
        ],
      ),
    );
  }

  Color _attendanceColor(double rate) {
    if (rate >= 0.80) return const Color(0xFF2E7D32);
    if (rate >= 0.60) return const Color(0xFFF59E0B);
    return const Color(0xFFE65D7B);
  }

  Color _absenceColor(double rate) {
    if (rate <= 0.10) return const Color(0xFF2E7D32);
    if (rate <= 0.20) return const Color(0xFFF59E0B);
    return const Color(0xFFE65D7B);
  }
}

// ─── Stat bar row ─────────────────────────────────────────────────────────────

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String   label;
  final double   value;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final percent = '${(value * 100).toInt()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            Text(
              percent,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Container(
                height: 8,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 8,
                width: constraints.maxWidth * value,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Shown in place of a bar when there isn't enough historical data yet.
class _NoDataRow extends StatelessWidget {
  const _NoDataRow({
    required this.icon,
    required this.label,
    required this.cs,
  });

  final IconData    icon;
  final String      label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16,
                color: cs.onSurface.withValues(alpha: 0.3)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          Text(
            'Not enough data',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
          ),
        ],
      );
}
