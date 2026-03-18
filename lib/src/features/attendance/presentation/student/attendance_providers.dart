import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';

/// Today's raw attendance record for the logged-in student (Node API).
///
/// Returns null if the student has not clocked in yet today.
/// Raw map is used so the clock-out handler can read the record `id`.
final studentTodayRawProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return null;

  final repo = ref.read(attendanceApiRepositoryProvider);
  return repo.getMyToday();
});

/// Recent 14-day attendance history for the logged-in student (Node API).
///
/// Used by the calendar and history list on the student attendance page.
final studentRecentAttendanceProvider =
    FutureProvider.autoDispose<List<AttendanceDay>>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return [];

  final repo = ref.read(attendanceApiRepositoryProvider);
  final records = await repo.getMyHistory(limit: 14);
  return records
      .map((r) => AttendanceDay.fromApiMap(r, studentUid: user.uid))
      .toList();
});

/// Present / absent summary derived from recent history.
final studentAttendanceSummaryProvider =
    FutureProvider.autoDispose<AttendanceSummary>((ref) async {
  final days = await ref.watch(studentRecentAttendanceProvider.future);
  return AttendanceSummary.fromDays(days);
});

/// Small value object used by the UI to show "Present 22 / Absent 3".
class AttendanceSummary {
  final int presentCount;
  final int absentCount;

  const AttendanceSummary({
    required this.presentCount,
    required this.absentCount,
  });

  factory AttendanceSummary.fromDays(List<AttendanceDay> days) {
    int present = 0;
    int absent = 0;

    for (final day in days) {
      if (day.status.isPresentLike) {
        present++;
      } else {
        absent++;
      }
    }

    return AttendanceSummary(presentCount: present, absentCount: absent);
  }
}
