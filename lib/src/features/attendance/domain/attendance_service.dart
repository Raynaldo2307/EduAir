// lib/src/features/attendance/domain/attendance_service.dart

import 'dart:developer' as dev;

import 'package:edu_air/src/features/attendance/data/attendance_repository.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';

/// AttendanceService
/// -----------------
/// Business rules for EduAir attendance (V1).
///
/// Handles:
/// - Clock in (early/late logic + late reason)
/// - Clock out (with early-leave / overtime flags)
/// - Loading today's record
/// - Loading recent history
///
/// It DOES NOT know about Firestore paths. It only talks to [AttendanceRepository].
class AttendanceService {
  final AttendanceRepository _repo;

  /// List of school holidays as "YYYY-MM-DD" keys.
  /// You can inject this from config / remote later.
  final Set<String> _schoolHolidayDateKeys;

  // ── Time / rule constants (easy to tweak or move to config later) ──
  static const int _classStartHour = 8;
  static const int _classStartMinute = 0;
  static const int _lateGraceMinutes = 30;

  static const int _classEndHour = 16; // 16:00 = 4:00 PM
  static const int _classEndMinute = 0;
  static const int _overtimeHour = 16; // 16:30 = 4:30 PM
  static const int _overtimeMinute = 30;

  AttendanceService({
    AttendanceRepository? repo,
    Set<String>? schoolHolidayDateKeys,
  }) : _repo = repo ?? AttendanceRepository(),
       _schoolHolidayDateKeys = schoolHolidayDateKeys ?? const {};

  /// Central place to get "school time".
  /// Later you can swap this to use a fixed timezone (e.g. America/Jamaica)
  /// via the timezone package or backend.
  DateTime schoolNow() => DateTime.now();

  /// Backwards compat – use [schoolNow] everywhere in this class.
  DateTime now() => schoolNow();

  /// Is this a valid school day? (no weekend, no holiday)
  bool _isSchoolDay(DateTime day) {
    final localDate = DateTime(day.year, day.month, day.day);

    // 1) Block weekends
    if (localDate.weekday == DateTime.saturday ||
        localDate.weekday == DateTime.sunday) {
      return false;
    }

    // 2) Block configured public holidays
    final key = AttendanceDay.dateKeyFor(localDate);
    return !_schoolHolidayDateKeys.contains(key);
  }

  /// Public helper so UI / other layers can ask:
  /// "Is this date a valid school day?"
  bool isSchoolDay(DateTime day) => _isSchoolDay(day);

  /// Convenience: get the dateKey for "today" in school time.
  String todayDateKey() => AttendanceDay.dateKeyFor(schoolNow());

  /// Class start (e.g. 08:00) in local time for the given day.
  DateTime _classStartFor(DateTime day) => DateTime(
    day.year,
    day.month,
    day.day,
    _classStartHour,
    _classStartMinute,
  );

  /// Class end (e.g. 16:00) in local time for the given day.
  DateTime _classEndFor(DateTime day) =>
      DateTime(day.year, day.month, day.day, _classEndHour, _classEndMinute);

  /// Overtime cutoff (e.g. 16:30) in local time for the given day.
  DateTime _overtimeCutoffFor(DateTime day) =>
      DateTime(day.year, day.month, day.day, _overtimeHour, _overtimeMinute);

  /// Student taps "Clock In".
  ///
  /// - Computes early/late using [AttendanceDay.resolveStatusFromClockIn].
  /// - Requires [lateReason] when status is `late`.
  /// - Writes/updates the day's record via the repository.
  ///
  /// Returns the saved [AttendanceDay].
  Future<AttendanceDay> clockIn({
    required String schoolId,
    required String studentUid,
    required AttendanceLocation location,
    String? lateReason,
    DateTime? at, // for tests or special cases; default = now()
  }) async {
    final ts = at ?? now();
    final dateKey = AttendanceDay.dateKeyFor(ts);

    // ⛔️ Block weekends / public holidays
    if (!_isSchoolDay(ts)) {
      throw StateError('Cannot clock in: not a school day (weekend/holiday).');
    }

    // If a record already exists with a clock-in time, treat this as idempotent
    // and just return the existing record.
    final existing = await _repo.getDay(
      schoolId: schoolId,
      studentUid: studentUid,
      dateKey: dateKey,
    );

    if (existing != null && existing.clockInAt != null) {
      return existing;
    }

    // Decide early vs late
    final status = AttendanceDay.resolveStatusFromClockIn(
      clockIn: ts,
      classStart: _classStartFor(ts),
      grace: const Duration(minutes: _lateGraceMinutes),
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
      lateReason: (cleanedReason == null || cleanedReason.isEmpty)
          ? null
          : cleanedReason,
    );

    try {
      await _repo.saveDay(
        schoolId: schoolId,
        studentUid: studentUid,
        day: day,
        isNew: existing == null,
      );
      return day;
    } catch (e, st) {
      // Keep this layer free of Firestore-specific types; just log and rethrow.
      dev.log(
        'AttendanceService.clockIn failed: $e',
        name: 'AttendanceService.clockIn',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Student taps "Clock Out".
  ///
  /// - Requires that the student already clocked in.
  /// - Adds `clockOutAt` and `clockOutLocation` to the day's record.
  /// - Classifies the clock-out as early-leave / overtime for analytics/UX.
  Future<AttendanceDay> clockOut({
    required String schoolId,
    required String studentUid,
    required AttendanceLocation location,
    DateTime? at,
  }) async {
    final ts = at ?? now();
    final dateKey = AttendanceDay.dateKeyFor(ts);

    // ⛔️ Block weekends / public holidays
    if (!_isSchoolDay(ts)) {
      throw StateError('Cannot clock out: not a school day (weekend/holiday).');
    }

    final classEnd = _classEndFor(ts);
    final overtimeCutoff = _overtimeCutoffFor(ts);

    // Load existing day so we can enforce "must clock in first" and
    // "no double clock-out".
    final existing = await _repo.getDay(
      schoolId: schoolId,
      studentUid: studentUid,
      dateKey: dateKey,
    );

    if (existing == null || existing.clockInAt == null) {
      throw StateError('Cannot clock out: no clock-in found for today.');
    }

    // ⛔️ Strict double clock-out rule
    if (existing.clockOutAt != null) {
      throw StateError('Cannot clock out twice for the same day.');
    }

    // Classify this clock-out
    final isEarlyLeave = ts.isBefore(classEnd);
    final isOvertime = ts.isAfter(overtimeCutoff);

    if (isEarlyLeave) {
      dev.log(
        'Early leave detected | schoolId=$schoolId, uid=$studentUid, '
        'date=$dateKey, clockOut=$ts',
        name: 'AttendanceService.clockOut',
      );
    } else if (isOvertime) {
      dev.log(
        'Overtime detected | schoolId=$schoolId, uid=$studentUid, '
        'date=$dateKey, clockOut=$ts',
        name: 'AttendanceService.clockOut',
      );
    }

    final updated = existing.copyWith(
      clockOutAt: ts,
      clockOutLocation: location,
      isEarlyLeave: isEarlyLeave,
      isOvertime: isOvertime,
    );

    await _repo.saveDay(
      schoolId: schoolId,
      studentUid: studentUid,
      day: updated,
      isNew: false,
    );

    return updated;
  }

  /// Load today's attendance record for this student, if any.
  Future<AttendanceDay?> getToday({
    required String schoolId,
    required String studentUid,
    DateTime? at,
  }) async {
    final ts = at ?? now();
    final dateKey = AttendanceDay.dateKeyFor(ts);

    return _repo.getDay(
      schoolId: schoolId,
      studentUid: studentUid,
      dateKey: dateKey,
    );
  }

  /// Load recent days (e.g., last 7 or 14) for history UI.
  Future<List<AttendanceDay>> getRecentDays({
    required String schoolId,
    required String studentUid,
    int limit = 14,
  }) {
    return _repo.getRecentDays(
      schoolId: schoolId,
      studentUid: studentUid,
      limit: limit,
    );
  }

  /// Convenience wrapper for UI code.
  Future<List<AttendanceDay>> getRecentDaysForStudent({
    required String schoolId,
    required String studentUid,
    int limit = 14,
  }) {
    return getRecentDays(
      schoolId: schoolId,
      studentUid: studentUid,
      limit: limit,
    );
  }
}
