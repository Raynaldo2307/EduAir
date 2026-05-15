import 'package:flutter/material.dart';

class AdminAnalyticsHeader extends StatelessWidget {
  const AdminAnalyticsHeader({
    super.key,
    required this.schoolName,
    this.onOpenDrawer,
  });

  final String schoolName;
  final VoidCallback? onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final date = '${now.day}/${now.month}/${now.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (onOpenDrawer != null)
          IconButton(
            onPressed: onOpenDrawer,
            icon: Icon(Icons.menu, color: cs.onSurface),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school_outlined, color: cs.primary, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              schoolName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              date,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.calendar_today_outlined, color: cs.onSurface),
        ),
      ],
    );
  }
}
