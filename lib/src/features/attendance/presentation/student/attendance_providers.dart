import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
// import 'package:edu_air/src/features/attendance/domain/attendance_service.dart';
// ^ Not needed here – we use attendanceServiceProvider from app_providers.dart

/// Recent attendance days for the *current* logged-in student.
/// In V1 we just load the last 14 days.
final studentRecentAttendanceProvider = FutureProvider<List<AttendanceDay>>((
  ref,
) async {
  final user = ref.watch(userProvider);
  final service = ref.watch(attendanceServiceProvider);

  // Not logged in → nothing to show.
  if (user == null) return [];

  final schoolId = user.schoolId;
  if (schoolId == null || schoolId.isEmpty) return [];

  return service.getRecentDays(
    schoolId: schoolId,
    studentUid: user.uid,
    limit: 14,
  );
});

/// Simple summary (present / absent counts) for the current student,
/// based on the recent days above.
final studentAttendanceSummaryProvider = FutureProvider<AttendanceSummary>((
  ref,
) async {
  final days = await ref.watch(studentRecentAttendanceProvider.future);
  return AttendanceSummary.fromDays(days);
});

/// Small value object used only by the UI to show "Present 22 / Absent 3".
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
