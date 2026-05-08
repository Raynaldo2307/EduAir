import 'package:flutter/material.dart';
import 'package:edu_air/src/core/app_theme.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({super.key});

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
          Text(
            'Stats',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _StatBar(
            label: 'Academic Achievement',
            value: 0.82,
            color: const Color(0xFF0059BA),
          ),
          const SizedBox(height: 12),
          _StatBar(
            label: 'Student Retention',
            value: 0.64,
            color: const Color(0xFFFF9F43),
          ),
          const SizedBox(height: 12),
          _StatBar(
            label: 'Staff Punctuality',
            value: 0.78,
            color: const Color(0xFF9B51E0),
          ),
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Container(
                height: 8,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
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
