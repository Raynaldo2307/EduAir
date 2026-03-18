import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';

/// Monthly calendar card showing per-day attendance status dots.
/// State (focusedMonth, today) is owned by the parent page.
/// Navigation callbacks keep setState in the parent too.
class AttendanceCalendar extends StatelessWidget {
  const AttendanceCalendar({
    super.key,
    required this.focusedMonth,
    required this.today,
    required this.recentAsync,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime focusedMonth;
  final DateTime today;
  final AsyncValue<List<AttendanceDay>> recentAsync;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  static const _weekdayShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  AttendanceDay? _findDayByKey(List<AttendanceDay> days, String key) {
    for (final d in days) {
      if (d.dateKey == key) return d;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)),
        ),
        padding: const EdgeInsets.all(12),
        child: recentAsync.when(
          data: (days) => _buildCalendar(context, theme, days),
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, __) => Center(
            child: Text(
              'Calendar unavailable',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    ThemeData theme,
    List<AttendanceDay> days,
  ) {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;

    final totalCells = (firstWeekday - 1) + daysInMonth;
    final weeks = (totalCells / 7).ceil();

    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final monthLabel =
        '${_monthNames[focusedMonth.month - 1]} ${focusedMonth.year}';

    int cellIndex = 0;
    final rows = <TableRow>[];

    for (int week = 0; week < weeks; week++) {
      rows.add(
        TableRow(
          children: List.generate(7, (col) {
            const cellHeight = 40.0;
            final dayNumber = cellIndex - (firstWeekday - 1) + 1;
            cellIndex++;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox(height: cellHeight);
            }

            final cellDate = DateTime(
              focusedMonth.year,
              focusedMonth.month,
              dayNumber,
            );
            final key = AttendanceDay.dateKeyFor(cellDate);
            final dayData = _findDayByKey(days, key);
            final status = dayData?.status ?? AttendanceStatus.absent;

            final inHighlightedRange =
                !cellDate.isBefore(weekStart) && !cellDate.isAfter(weekEnd);

            Color dotColor;
            if (status.isPresentLike) {
              dotColor = const Color(0xFF2F9E44);
            } else if (status == AttendanceStatus.late) {
              dotColor = const Color(0xFFE8590C);
            } else {
              dotColor = theme.colorScheme.outline.withValues(alpha: 0.4);
            }

            final isToday =
                AttendanceDay.dateKeyFor(cellDate) ==
                AttendanceDay.dateKeyFor(today);

            return SizedBox(
              height: cellHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 2.5,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: inHighlightedRange
                        ? (theme.brightness == Brightness.dark
                            ? AppTheme.darkCard.withValues(alpha: 0.8)
                            : AppTheme.heroStripBackground.withValues(alpha: 0.7))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(
                            color: AppTheme.primaryColor,
                            width: 1.4,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNumber.toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }

    return Column(
      children: [
        // ── Month header + prev/next ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.chevron_left),
              onPressed: onPreviousMonth,
            ),
            Text(
              monthLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.chevron_right),
              onPressed: onNextMonth,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Weekday labels ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            return Expanded(
              child: Center(
                child: Text(
                  _weekdayShort[index],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),

        // ── Month grid ──
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: rows,
        ),
      ],
    );
  }
}
