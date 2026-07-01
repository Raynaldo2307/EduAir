import 'package:dio/dio.dart';

import 'package:edu_air/src/services/api_client.dart';
import 'package:edu_air/src/features/Teacher/lesson_attendance/domain/lesson_attendance_models.dart';

/// Talks to `/api/lesson-attendance` — per-subject (lesson-level) attendance.
///
/// school_id and the marking teacher are enforced server-side from the JWT; the
/// client never sends them. The subject, class and shift are taken from the
/// timetable period, so the client sends only the period id + the marks. This is
/// separate from [TeacherAttendanceDataSource], which drives the daily register.
///
/// Scale note (built for a Monday morning across ~1k schools): every write is a
/// SINGLE batch request for the whole class — the server upserts in one
/// transaction — so marking 40 students costs one round trip, not 40.
class LessonAttendanceApiRepository {
  LessonAttendanceApiRepository({required ApiClient client}) : _dio = client.dio;

  final Dio _dio;

  /// POST /api/lesson-attendance — save the whole roll for one period in one
  /// request. Idempotent: safe to call again for the same period+date (the
  /// server updates existing marks instead of duplicating and logs each change).
  ///
  /// [dateKey] is 'YYYY-MM-DD' in the school's timezone. Omitting it lets the
  /// server default to today, but the caller passes it explicitly so the roll is
  /// unambiguous.
  Future<LessonMarkResult> mark({
    required int timetableEntryId,
    required String dateKey,
    required List<LessonMarkEntry> entries,
  }) async {
    final response = await _dio.post('/api/lesson-attendance', data: {
      'timetable_entry_id': timetableEntryId,
      'attendance_date': dateKey,
      'entries': entries.map((e) => e.toJson()).toList(),
    });
    return LessonMarkResult.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }

  /// GET /api/lesson-attendance?timetable_entry_id=&date= — existing marks for a
  /// period on a date, used to PRE-FILL the roll so a teacher edits rather than
  /// re-enters. Returns an empty list when nothing has been marked yet.
  Future<List<ExistingLessonMark>> getForEntry({
    required int timetableEntryId,
    required String dateKey,
  }) async {
    final response = await _dio.get(
      '/api/lesson-attendance',
      queryParameters: {
        'timetable_entry_id': timetableEntryId,
        'date': dateKey,
      },
    );
    final rows = List<Map<String, dynamic>>.from(response.data['data'] as List);
    return rows.map(ExistingLessonMark.fromJson).toList();
  }
}
