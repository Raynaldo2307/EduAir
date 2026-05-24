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
    this.width,
    this.trend,
    this.trendUp,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color iconColor;
  // null on desktop — card fills Expanded width. Fixed on mobile scroll.
  final double? width;
  // Optional trend line shown at the bottom of the card.
  // trendUp=true → green (improvement), false → red (worse), null → no arrow.
  final String? trend;
  final bool? trendUp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trendColor = trendUp == true
        ? const Color(0xFF2E7D32)
        : const Color(0xFFE65D7B);

    return Container(
      width: width,           // null = fills Expanded, fixed = mobile scroll
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? iconColor.withValues(alpha: 0.2) : color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow(isDark: isDark, primary: iconColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  trendUp == true
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 10,
                  color: trendColor,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    trend!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: trendColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
