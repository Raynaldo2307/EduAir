// lib/src/features/attendance/widgets/attendance_status_strip.dart

import 'package:flutter/material.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';

/// Small horizontal strip that shows **today's attendance status**.
///
/// V1 usage:
/// - Pass in today's [AttendanceDay] (or null if no record).
/// - The widget stays dumb: it only formats and displays.
///
/// Example:
/// ```dart
/// AttendanceStatusStrip(today: todayAttendanceDay);
/// ```
class AttendanceStatusStrip extends StatelessWidget {
  const AttendanceStatusStrip({super.key, required this.today});

  /// Today's attendance record, or null if nothing recorded yet.
  final AttendanceDay? today;

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);

    // No record yet → neutral message.
    if (today == null) {
      return _buildContainer(
        context,
        leadingColor: AppTheme.grey,
        title: 'Today',
        subtitle: 'No attendance recorded yet',
      );
    }

    // Choose color based on status.
    final status = today!.status;
    final statusLabel = status.label;

    Color chipColor;
    switch (status) {
      case AttendanceStatus.early:
        chipColor = Colors.green.shade500;
        break;
      case AttendanceStatus.late:
        chipColor = Colors.orange.shade600;
        break;
      case AttendanceStatus.present:
        chipColor = AppTheme.primaryColor;
        break;
      case AttendanceStatus.absent:
        chipColor = Colors.red.shade500;
        break;
    }

    final inTime = _formatTime(context, today!.clockInAt);
    final outTime = _formatTime(context, today!.clockOutAt);

    String subtitle;
    if (status == AttendanceStatus.absent) {
      // Optional: show excused note if we ever store that in lateReason.
      subtitle = today!.lateReason?.isNotEmpty == true
          ? 'Absent • ${today!.lateReason}'
          : 'Absent';
    } else if (inTime == null && outTime == null) {
      subtitle = statusLabel;
    } else if (inTime != null && outTime != null) {
      subtitle = '$statusLabel • In: $inTime  ·  Out: $outTime';
    } else if (inTime != null) {
      subtitle = '$statusLabel • In: $inTime';
    } else {
      subtitle = statusLabel;
    }

    return _buildContainer(
      context,
      leadingColor: chipColor,
      title: 'Today',
      subtitle: subtitle,
    );
  }

  /// Builds the common container UI.
  Widget _buildContainer(
    BuildContext context, {
    required Color leadingColor,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Left colored dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: leadingColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, // "Today"
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.textPrimary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Format time like "8:05 AM". Returns null if [dt] is null.
  String? _formatTime(BuildContext context, DateTime? dt) {
    if (dt == null) return null;
    final timeOfDay = TimeOfDay.fromDateTime(dt);
    return timeOfDay.format(context);
  }
}
