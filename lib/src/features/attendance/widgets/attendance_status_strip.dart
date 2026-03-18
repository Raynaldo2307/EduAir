// lib/src/features/attendance/widgets/attendance_status_strip.dart

/// AttendanceStatusStrip
/// ---------------------
///
/// Single place that explains **today's attendance** to the student.
///
/// Inputs:
/// - [today]      → today's AttendanceDay record, or null if nothing in Firestore.
/// - [isSchoolDay]→ true if this date is a valid school day (no weekend/holiday),
///                  coming from AttendanceService.isSchoolDay(...).
///
/// UX rules (Jan 2026):
/// - Non-school day (isSchoolDay == false):
///     → Always show "No school today". We ignore the 10:00 AM rule here.
/// - School day, no [today] record:
///     → Before 10:00  → "No attendance recorded yet".
///     → At/after 10:00→ "Absent (no clock-in by 10:00 AM)".
///       NOTE: this is **UI-only**. We do NOT write `status: absent` to Firestore.
///       A future admin/cron process will be responsible for persisting absences.
/// - School day with [today] record:
///     → Format status ("Early", "Late", "Present", "Absent") plus:
///         * In/Out times when available.
///         * Small chips for `isEarlyLeave` ("Left early")
///           and `isOvertime` ("Overtime").
///
/// This keeps all "how do we describe today?" logic in one widget, while the
/// real business rules (what can be written, when, and by whom) stay in
/// AttendanceService.
library;

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
  const AttendanceStatusStrip({
    super.key,
    required this.today,
    this.isSchoolDay = true,
  });

  /// Today's attendance record, or null if nothing recorded yet.
  final AttendanceDay? today;

  /// Whether today is a valid school day (not weekend / holiday).
  final bool isSchoolDay;

  @override
  Widget build(BuildContext context) {
    // If today is not a school day (weekend / holiday),
    // show a neutral "No school today" strip.
    if (!isSchoolDay) {
      return _buildContainer(
        context,
        leadingColor: AppTheme.grey,
        title: 'Today',
        subtitle: 'No school today',
      );
    }

    // No record yet → decide based on time (10:00 AM rule).
    if (today == null) {
      final now = DateTime.now();
      final absenteeCutoff = DateTime(now.year, now.month, now.day, 10, 0);
      final isAfterCutoff =
          now.isAfter(absenteeCutoff) || now.isAtSameMomentAs(absenteeCutoff);

      // Before 10:00 → neutral "not yet clocked in"
      if (!isAfterCutoff) {
        return _buildContainer(
          context,
          leadingColor: AppTheme.grey,
          title: 'Today',
          subtitle: 'Not yet clocked in',
        );
      }

      // At or after 10:00 → treat as absent in UI
      return _buildContainer(
        context,
        leadingColor: Colors.red.shade500,
        title: 'Today',
        subtitle: 'Absent (no clock-in by 10:00 AM)',
      );
    }

    // From here on we know we have a record.
    final day = today!;
    final status = day.status;
    final statusLabel = status.label;

    // Choose color based on status.
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
      case AttendanceStatus.excused:
        chipColor = Colors.amber.shade600;
        break;
    }

    final inTime = _formatTime(context, day.clockInAt);
    final outTime = _formatTime(context, day.clockOutAt);

    // Build small tags for early-leave / overtime
    final tags = <String>[];
    if (day.isEarlyLeave) {
      tags.add('Left early');
    }
    if (day.isOvertime) {
      tags.add('Overtime');
    }

    String subtitle;
    if (status == AttendanceStatus.absent) {
      // Optional: show excused note if we ever store that in lateReason.
      subtitle = day.lateReason?.isNotEmpty == true
          ? 'Absent • ${day.lateReason}'
          : 'Absent';
    } else if (status == AttendanceStatus.excused) {
      subtitle = day.lateReason?.isNotEmpty == true
          ? 'Excused • ${day.lateReason}'
          : 'Excused';
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
      tags: tags,
    );
  }

  /// Builds the common container UI.
  Widget _buildContainer(
    BuildContext context, {
    required Color leadingColor,
    required String title,
    required String subtitle,
    List<String> tags = const [],
  }) {
    final theme = Theme.of(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.surfaceVariant,
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // Tiny chips row for tags (Left early / Overtime)
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              t,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
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
