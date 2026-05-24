import 'package:flutter/material.dart';

class AdminAnalyticsHeader extends StatelessWidget {
  const AdminAnalyticsHeader({
    super.key,
    required this.schoolName,
    this.onOpenDrawer,
  });

  final String schoolName;
  final VoidCallback? onOpenDrawer;

  static const _weekdays = [
    '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static const _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _formattedDate(DateTime d) {
    final weekday = _weekdays[d.weekday];
    final month = _months[d.month];
    return '$weekday, $month ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onOpenDrawer != null) ...[
          IconButton(
            onPressed: onOpenDrawer,
            icon: Icon(Icons.menu, color: cs.onSurface),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school, color: cs.primary, size: 26),
                  const SizedBox(width: 6),
                  Text(
                    'Analytics',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                schoolName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formattedDate(now),
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.calendar_today_outlined, color: cs.onSurface),
        ),
      ],
    );
  }
}
