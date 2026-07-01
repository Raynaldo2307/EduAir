import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';

/// Lesson (subject) attendance — the models the Flutter client sends to and
/// reads from `/api/lesson-attendance`.
///
/// This is DISTINCT from the daily SF4 register (`/api/attendance`). A subject
/// teacher marks ONE timetable period; the backend takes the subject, class and
/// shift FROM that period, so the client only ever sends the period id + the
/// per-student marks. Reuses [AttendanceStatus] — but a lesson can only be
/// present/late/absent/excused (never `early`; that is a clock-in idea).

/// Parse a backend status string ('present'…) into [AttendanceStatus].
/// Falls back to present on anything unexpected so the roll never crashes.
AttendanceStatus lessonStatusFromString(String? value) {
  if (value == null || value.isEmpty) return AttendanceStatus.present;
  for (final s in AttendanceStatus.values) {
    if (s.name == value) return s;
  }
  return AttendanceStatus.present;
}

/// One student's mark to SEND when saving a lesson roll.
class LessonMarkEntry {
  const LessonMarkEntry({
    required this.studentId,
    required this.status,
    this.lateReasonCode,
    this.note,
  });

  final int studentId;
  final AttendanceStatus status;
  final String? lateReasonCode; // MoEYI code — only meaningful on `late`
  final String? note;

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'status': status.name,
        // Only send a reason when one was actually picked. The backend already
        // clears the reason on any non-late status, so we never send a stale one.
        if (lateReasonCode != null && lateReasonCode!.isNotEmpty)
          'late_reason_code': lateReasonCode,
        if (note != null && note!.isNotEmpty) 'note': note,
      };
}

/// An existing mark READ BACK to pre-fill the roll (GET by period + date).
/// Carries the student's name so the roll can render without a second lookup.
class ExistingLessonMark {
  const ExistingLessonMark({
    required this.id,
    required this.studentId,
    required this.status,
    this.lateReasonCode,
    this.studentFirstName,
    this.studentLastName,
  });

  final int id;
  final int studentId;
  final AttendanceStatus status;
  final String? lateReasonCode;
  final String? studentFirstName;
  final String? studentLastName;

  factory ExistingLessonMark.fromJson(Map<String, dynamic> m) => ExistingLessonMark(
        id: (m['id'] as num).toInt(),
        studentId: (m['student_id'] as num).toInt(),
        status: lessonStatusFromString(m['status'] as String?),
        lateReasonCode: m['late_reason_code']?.toString(),
        studentFirstName: m['student_first_name']?.toString(),
        studentLastName: m['student_last_name']?.toString(),
      );
}

/// The summary the POST returns — used to confirm the save to the teacher
/// ("Saved 32 marks for English") without re-fetching.
class LessonMarkResult {
  const LessonMarkResult({
    required this.saved,
    required this.subject,
    required this.classId,
    required this.date,
  });

  final int saved;
  final String subject;
  final int classId;
  final String date;

  factory LessonMarkResult.fromJson(Map<String, dynamic> m) => LessonMarkResult(
        saved: (m['saved'] as num).toInt(),
        subject: (m['subject'] ?? '').toString(),
        classId: (m['class_id'] as num).toInt(),
        date: (m['date'] ?? '').toString(),
      );
}
