import 'package:flutter/material.dart';
import 'package:edu_air/src/core/app_theme.dart';

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? iconColor.withValues(alpha: 0.2) : color,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.3 : 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white : iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
