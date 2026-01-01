// lib/src/features/attendance/domain/attendance_service.dart

import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/attendance/data/attendance_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

/// AttendanceService
/// -----------------
/// Business rules for EduAir attendance (V1).
///
/// Handles:
/// - Clock in (early/late logic + late reason)
/// - Clock out
/// - Loading today's record
/// - Loading recent history
///
/// It DOES NOT know about Firestore. It only talks to [AttendanceRepository].
class AttendanceService {
  final AttendanceRepository _repo;

  AttendanceService({AttendanceRepository? repo})
    : _repo = repo ?? AttendanceRepository();

  /// Convenience: current time (can be overridden in tests).
  DateTime now() => DateTime.now();

  /// Class start (08:00) in local time for the given day.
  DateTime _classStartFor(DateTime day) =>
      DateTime(day.year, day.month, day.day, 8, 0);

  /// Student taps "Clock In".
  ///
  /// - Computes early/late using [AttendanceDay.resolveStatusFromClockIn].
  /// - Requires [lateReason] when status is `late`.
  /// - Writes/updates the day's doc in Firestore via the repository.
  ///
  /// Returns the saved [AttendanceDay].
  Future<AttendanceDay> clockIn({
    required String studentUid,
    required AttendanceLocation location,
    String? lateReason,
    DateTime? at, // for tests or special cases; default = now()
  }) async {
    final ts = at ?? now();
    final dateKey = AttendanceDay.dateKeyFor(ts);

    // Load existing day (if any) so we can prevent double clock-in
    final existing = await _repo.getDay(
      studentUid: studentUid,
      dateKey: dateKey,
    );

    if (existing != null && existing.clockInAt != null) {
      // Already clocked in; for now, just return the existing record.
      // You can change this to throw if you want strict behaviour.
      return existing;
    }

    // Decide early vs late
    final status = AttendanceDay.resolveStatusFromClockIn(
      clockIn: ts,
      classStart: _classStartFor(ts),
      grace: const Duration(minutes: 30),
    );

    // If late, we require a reason from the UI
    if (status == AttendanceStatus.late &&
        (lateReason == null || lateReason.trim().isEmpty)) {
      throw StateError('Late clock-in must include a late reason.');
    }

final cleanedReason = lateReason?.trim();

    final day = AttendanceDay(
      dateKey: dateKey,
      studentUid: studentUid,
      status: status,
      clockInAt: ts,
      clockInLocation: location,
      //lateReason: lateReason?.trim().isEmpty ?? true
          //? null
          //: lateReason!.trim(),
    lateReason:(cleanedReason == null || cleanedReason.isEmpty)
         ? null
         : cleanedReason,
    );

      try {
    await _repo.saveDay(
      studentUid: studentUid,
      day: day,
      isNew: existing == null,
    );

    return day;
  } on FirebaseException catch (e) {
    dev.log(
      '🔥 Firestore clockIn error: code=${e.code}, message=${e.message}',
      name: 'AttendanceService.clockIn',
      error: e,
    );
    rethrow;
  }
  }
     /// Student taps "Clock Out".
  ///
  /// - Requires that the student already clocked in.
  /// - Adds `clockOutAt` and `clockOutLocation` to the day's record.
  Future<AttendanceDay> clockOut({
    required String studentUid,
    required AttendanceLocation location,
    DateTime? at,
  }) async {
    final ts = at ?? now();
    final dateKey = AttendanceDay.dateKeyFor(ts);

    final existing = await _repo.getDay(
      studentUid: studentUid,
      dateKey: dateKey,
    );

    if (existing == null || existing.clockInAt == null) {
      throw StateError('Cannot clock out: no clock-in found for today.');
    }

    final updated = existing.copyWith(
      clockOutAt: ts,
      clockOutLocation: location,
    );

    await _repo.saveDay(studentUid: studentUid, day: updated, isNew: false);

    return updated;
  }

  /// Load today's attendance record for this student, if any.
  Future<AttendanceDay?> getToday({
    required String studentUid,
    DateTime? at,
  }) async {
    final ts = at ?? now();
    final dateKey = AttendanceDay.dateKeyFor(ts);

    return _repo.getDay(studentUid: studentUid, dateKey: dateKey);
  }

  /// Load recent days (e.g., last 7 or 14) for history UI.
  Future<List<AttendanceDay>> getRecentDays({
    required String studentUid,
    int limit = 14,
  }) {
    return _repo.getRecentDays(studentUid: studentUid, limit: limit);
  }
// Convenience wrapper for ui code .
Future<List<AttendanceDay>> getRecentDaysForStudent({

  required String studentUid,
  int limit = 14,
})
{
  return getRecentDays(studentUid: studentUid, limit:limit);
}
}

