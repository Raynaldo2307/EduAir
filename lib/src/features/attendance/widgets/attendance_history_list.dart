// lib/src/features/attendance/widgets/attendance_history_list.dart

import 'package:flutter/material.dart';

import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/attendance/widgets/attendance_day_tile.dart';

class AttendanceHistoryList extends StatelessWidget {
  const AttendanceHistoryList({
    super.key,
    required this.days,
    this.emptyMessage = 'No attendance history yet',
  });

  final List<AttendanceDay> days;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    Theme.of(context).textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.7,
                        ),
              ),
        ),
      );
    }

    return Column(
      children: [
        for (final day in days) AttendanceDayTile(day: day),
      ],
    );
  }
}