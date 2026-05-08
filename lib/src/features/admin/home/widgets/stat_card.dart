import 'package:flutter/material.dart';
import 'package:edu_air/src/core/app_theme.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.iconColor,
    required this.width,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color iconColor;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? iconColor.withValues(alpha: 0.2) : color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
