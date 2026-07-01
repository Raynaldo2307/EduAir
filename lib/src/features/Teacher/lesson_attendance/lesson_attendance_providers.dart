import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
// NOTE: lowercase `teacher/` on purpose. The daily-roll code imports its models
// with this casing, and Dart treats a differently-cased path as a DIFFERENT type
// (even on a case-insensitive filesystem). Matching the casing keeps the
// TeacherClassOption / TeacherAttendanceStudent types identical, so reuse works.
import 'package:edu_air/src/features/teacher/attendance/domain/teacher_attendance_models.dart';
import 'package:edu_air/src/features/teacher/attendance/teacher_attendance_providers.dart';
import 'package:edu_air/src/features/Teacher/lesson_attendance/domain/lesson_attendance_models.dart';

/// Providers that feed the lesson-roll screen: the ROSTER (who's in the class)
/// and the PREFILL (what's already marked for this period today).

/// ROSTER — the students registered to the tapped period's class.
///
/// Deliberately REUSES the daily register's roster path (`GET /api/students?
/// class_id=`) via [teacherAttendanceRepositoryProvider], so a subject teacher
/// and a homeroom teacher pull the exact same student list for a class — lesson
/// and daily can never drift apart. Keyed by the period's `class_id` (an int),
/// which is all the query needs; the class label isn't sent, so a placeholder is
/// fine. autoDispose so each opened period fetches fresh.
final lessonRosterProvider = FutureProvider.autoDispose
    .family<List<TeacherAttendanceStudent>, int>((ref, classId) async {
  final schoolId = ref.read(userProvider)?.schoolId ?? '';
  final repo = ref.read(teacherAttendanceRepositoryProvider);
  return repo.getStudentsForClass(
    schoolId: schoolId,
    classOption: TeacherClassOption(
      classId: classId.toString(),
      className: 'Class', // label only — not used by the students query
    ),
  );
});

/// Query key for "which marks already exist for this period on this date?"
class LessonMarksQuery {
  const LessonMarksQuery({
    required this.timetableEntryId,
    required this.dateKey,
  });

  final int timetableEntryId;
  final String dateKey;

  @override
  bool operator ==(Object other) =>
      other is LessonMarksQuery &&
      other.timetableEntryId == timetableEntryId &&
      other.dateKey == dateKey;

  @override
  int get hashCode => Object.hash(timetableEntryId, dateKey);
}

/// PREFILL — existing marks for one period on one date, as a map keyed by the
/// student's id (as a String, matching [TeacherAttendanceStudent.uid]) so the
/// roll can look up a student's current status in O(1). Empty map = nothing
/// marked yet. autoDispose.
final lessonMarksForEntryProvider = FutureProvider.autoDispose
    .family<Map<String, ExistingLessonMark>, LessonMarksQuery>((ref, q) async {
  final repo = ref.read(lessonAttendanceApiRepositoryProvider);
  final marks = await repo.getForEntry(
    timetableEntryId: q.timetableEntryId,
    dateKey: q.dateKey,
  );
  return {for (final m in marks) m.studentId.toString(): m};
});
