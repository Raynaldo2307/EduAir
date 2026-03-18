// lib/src/features/attendance/widgets/attendance_day_tile.dart

import 'package:flutter/material.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';

class AttendanceDayTile extends StatelessWidget {
  const AttendanceDayTile({
    super.key,
    required this.day,
  });

  final AttendanceDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final date = _parseDate(day.dateKey);
    final dateLabel = _formatDate(date);
    final statusLabel = day.status.label;
    final statusColor = _statusColor(day.status);
    final statusBg = statusColor.withValues(alpha: 0.12);

    String? timeText;
    if (day.clockInAt != null) {
      final time = day.clockInAt!;
      final hh = time.hour.toString().padLeft(2, '0');
      final mm = time.minute.toString().padLeft(2, '0');
      timeText = '$hh:$mm';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? AppTheme.darkCard : AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Colored dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),

          // Date + maybe time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (timeText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Clock-in: $timeText',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ------------------------------------------------

  DateTime _parseDate(String key) {
    // Expects "YYYY-MM-DD"
    final parts = key.split('-');
    if (parts.length != 3) return DateTime.now();
    final y = int.tryParse(parts[0]) ?? DateTime.now().year;
    final m = int.tryParse(parts[1]) ?? DateTime.now().month;
    final d = int.tryParse(parts[2]) ?? DateTime.now().day;
    return DateTime(y, m, d);
  }

  String _formatDate(DateTime d) {
    // Simple: Mon, Dec 23
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final wd = weekdays[(d.weekday - 1) % 7];
    final m = months[(d.month - 1) % 12];
    return '$wd, $m ${d.day}';
  }

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.early:
        return const Color(0xFF2F9E44); // greenish
      case AttendanceStatus.late:
        return const Color(0xFFE65D7B); // reddish
      case AttendanceStatus.present:
        return AppTheme.primaryColor;
      case AttendanceStatus.absent:
        return const Color(0xFF9E9E9E); // grey
      case AttendanceStatus.excused:
        return const Color(0xFFF2B233); // amber
    }
  }
}
