// lib/src/features/attendance/data/attendance_repository.dart

import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/attendance/data/attendance_firestore_source.dart';

/// AttendanceRepository
/// --------------------
/// Single "door" for reading/writing attendance data in EduAir.
///
/// - The rest of the app should talk to THIS class, not directly to Firestore.
/// - It hides the Firestore details (paths, maps, GeoPoint, Timestamp, etc.).
/// - Later we can plug in offline/local storage without touching the UI.
///
/// Current Firestore layout (multi-school):
///   schools/{schoolId}/attendance/{YYYY-MM-DD}_{studentUid}
///
/// Each document maps to an [AttendanceDay] (one student, one school day).

class AttendanceRepository {
  final AttendanceFirestoreSource _remote;
  AttendanceRepository({AttendanceFirestoreSource? remote})
    : _remote = remote ?? AttendanceFirestoreSource();

  /// Get a single day of attendance for a student.
  ///
  /// Returns `null` if there's no record for that day yet.
  ///
  Future<AttendanceDay?> getDay({
    required String schoolId,
    required String studentUid,
    required String dateKey, //"YYYY-MM-DD"
  }) {
    return _remote.getDay(
      schoolId: schoolId,
      studentUid: studentUid,
      dateKey: dateKey,
    );
  }

  /// Get the most recent [limit] days of attendance for a student,
  /// ordered by date descending (today first).
  Future<List<AttendanceDay>> getRecentDays({
    required String schoolId,
    required String studentUid,
    int limit = 14,
  }) {
    return _remote.getRecentDays(
      schoolId: schoolId,
      studentUid: studentUid,
      limit: limit,
    );
  }

  /// Create or update a daily attendance document.
  Future<AttendanceDay> saveDay({
    required String schoolId,
    required String studentUid,
    required AttendanceDay day,
    bool isNew = false,
  }) async {
    // Note: we trust [day.dateKey] + studentUid to form the doc id.
    await _remote.saveDay(
      schoolId: schoolId,
      studentUid: studentUid,
      day: day,
      isNew: isNew,
    );

    // For now, simply return the same day we just saved. If in the future
    // you need server-populated fields (e.g. server timestamps), you could
    // re-fetch the document here and return the updated model instead.
    return day;
  }

  // Optional: stream a single day's record so UI can react in real-time
  // (e.g. after admin overrides)
  Stream<AttendanceDay?> watchDay({
    required String schoolId,
    required String studentUid,
    required String dateKey,
  }) {
    return _remote.watchDay(
      schoolId: schoolId,
      studentUid: studentUid,
      dateKey: dateKey,
    );
  }
}
