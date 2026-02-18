// lib/src/features/attendance/domain/attendance_service.dart

import 'dart:developer' as dev;

import 'package:edu_air/src/features/attendance/data/attendance_repository.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_exceptions.dart';
import 'package:edu_air/src/services/user_services.dart';

/// AttendanceService (V2 - Shift-Aware)
/// ------------------------------------
/// Business rules for EduAir attendance with Jamaican shift system support.
///
/// Handles:
/// - Clock in (shift-aware early/late logic + MoEYI late reason validation)
/// - Clock out (with early-leave / overtime flags)
/// - Loading today's record (shift-specific)
/// - Loading recent history (shift-specific)
///
/// It DOES NOT know about Firestore paths. It only talks to [AttendanceRepository]
/// and [UserService].
///
/// Key design principles:
/// - Shift-aware: Uses student's shiftType (will come from profile later)
/// - Idempotent: Safe to call clock-in/out multiple times
/// - Historically safe: Never recomputes old records when shift changes
/// - Pure domain logic: No UI code (BuildContext, SnackBar, setState)
class AttendanceService {
  final AttendanceRepository _repo;
  final UserService _userService;

  /// List of school holidays as "YYYY-MM-DD" keys.
  /// You can inject this from config / remote later.
  final Set<String> _schoolHolidayDateKeys;

  // ── Grace period constants (easy to tweak or move to config later) ──
  static const int _lateGraceMinutes = 30;

  AttendanceService({
    AttendanceRepository? repo,
    UserService? userService,
    Set<String>? schoolHolidayDateKeys,
  }) : _repo = repo ?? AttendanceRepository(),
       _userService = userService ?? UserService(),
       _schoolHolidayDateKeys = schoolHolidayDateKeys ?? const {};

  /// Central place to get "school time".
  ///
  /// ⚠️ TODO (DPA 2020 Compliance): Replace with NTP/server time to prevent
  /// device clock spoofing. Under Jamaican Data Protection Act 2020, attendance
  /// records must be authentic and tamper-proof.
  ///
  /// For now, this uses device time normalized to school timezone.
  DateTime schoolNow() => DateTime.now();

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

  /// Jamaican shift system resolver.
  ///
  /// **Context:**
  /// Many Jamaican schools operate shift systems to maximize limited
  /// infrastructure. Legally, each shift is treated as a **separate school day**
  /// for attendance and reporting purposes.
  ///
  /// **Shift times:**
  /// - `morning`: 7:00 AM - 12:00 PM
  /// - `afternoon` / `evening`: 12:00 PM - 5:00 PM
  /// - `whole_day` (or unknown): 8:00 AM (default single-shift schools)
  ///
  /// **Returns:** The expected start time for the given shift on the given date.
  DateTime _getExpectedStartTime({
    required String shiftType,
    required DateTime date,
  }) {
    final normalized = AttendanceDay.normalizeShiftType(shiftType);

    switch (normalized) {
      case 'morning':
        // Morning shift starts at 7:00 AM
        return DateTime(date.year, date.month, date.day, 7, 0);

      case 'afternoon':
        // Afternoon/evening shifts start at 12:00 PM (noon)
        // Note: 'evening' is aliased to 'afternoon' in normalizeShiftType
        return DateTime(date.year, date.month, date.day, 12, 0);

      case 'whole_day':
      default:
        // Whole-day or unknown defaults to 8:00 AM
        return DateTime(date.year, date.month, date.day, 8, 0);
    }
  }

  /// Class end (e.g. 16:00) in local time for the given day.
  ///
  /// Class end in local time for the given day **and shift**.
  ///
  /// - Morning shift ends at 12:00 PM
  /// - Afternoon shift ends at 5:00 PM
  /// - Whole-day (or unknown) ends at 4:00 PM (legacy default)
  DateTime _classEndFor(DateTime day, String shiftType) {
    final normalized = AttendanceDay.normalizeShiftType(shiftType);

    switch (normalized) {
      case 'morning':
        return DateTime(day.year, day.month, day.day, 12, 0);
      case 'afternoon':
        return DateTime(day.year, day.month, day.day, 17, 0);
      case 'whole_day':
      default:
        // Keep your previous behaviour for whole_day
        return DateTime(day.year, day.month, day.day, 16, 0);
    }
  }

  /// Overtime cutoff in local time for the given day **and shift**.
  ///
  /// - Morning shift overtime after 12:30 PM
  /// - Afternoon shift overtime after 5:30 PM
  /// - Whole-day overtime after 4:30 PM (legacy default)
  DateTime _overtimeCutoffFor(DateTime day, String shiftType) {
    final normalized = AttendanceDay.normalizeShiftType(shiftType);

    switch (normalized) {
      case 'morning':
        return DateTime(day.year, day.month, day.day, 12, 30);
      case 'afternoon':
        return DateTime(day.year, day.month, day.day, 17, 30);
      case 'whole_day':
      default:
        // Keep your previous behaviour for whole_day
        return DateTime(day.year, day.month, day.day, 16, 30);
    }
  }

  /// Student taps "Clock In".
  ///
  /// **Flow:**
  /// 1. Validate school day (no weekend/holiday)
  /// 2. Determine shiftType for this student (currently always `whole_day`)
  /// 3. Compute start time + grace, decide early/late
  /// 4. Validate MoEYI late reason if late
  /// 5. Write/update the day's record (idempotent if already clocked in)
  ///
  /// **Throws:**
  /// - [NotSchoolDayException] if weekend/holiday
  /// - [LateReasonRequiredException] if late without valid reason
  /// - [InvalidLateReasonException] if reason is not a MoEYI category
  /// - [AttendancePersistenceException] on persistence errors
  ///
  /// **Returns:** The saved [AttendanceDay].
  /// 
  
  Future<AttendanceDay> clockIn({
    required String schoolId,
    required String studentUid,
    required AttendanceLocation location,
    String? classId,
    String? className,
    int? gradeLevel,
    String? lateReason, // MoEYI category code (e.g., 'transportation')
    String? deviceId, // Device identifier for anti-fraud
    DateTime? at, // for tests or special cases; default = now()
  }) async {
    final ts = at ?? schoolNow();
    final dateKey = AttendanceDay.dateKeyFor(ts);

    // ⛔️ Block weekends / public holidays
    if (!_isSchoolDay(ts)) {
      throw const NotSchoolDayException();
    }

    // Optional sanity check: ensure student profile exists.
    // (Later, when AppUser has currentShift, we'll read shift from here.)
    final student = await _userService.getUser(studentUid);
    if (student == null) {
      throw AttendancePersistenceException(
        'Student profile not found: $studentUid',
      );
    }

    // For now, default every student to whole_day.
    //  When AppUser has currentShift/shiftType, derive it from [student].
    // Use student's currentShift from AppUser; AttendanceDay will
    // default to 'whole_day' if this is null or invalid.
    final rawShift = student.currentShift;
    final shiftType = AttendanceDay.normalizeShiftType(rawShift);

    // ✅ Check for existing record (idempotency)
    final existing = await _repo.getDay(
      schoolId: schoolId,
      studentUid: studentUid,
      dateKey: dateKey,
      shiftType: shiftType,
    );

    if (existing != null && existing.clockInAt != null) {
      // Already clocked in for this shift/day - return existing record
      return existing;
    }

    // ✅ Compute shift-aware expected start time and grace cutoff
    final expectedStart = _getExpectedStartTime(shiftType: shiftType, date: ts);
    final graceCutoff = expectedStart.add(
      const Duration(minutes: _lateGraceMinutes),
    );

    // ✅ Decide early vs late using shift-aware times
    final AttendanceStatus status;
    if (ts.isBefore(graceCutoff) || ts.isAtSameMomentAs(graceCutoff)) {
      status = AttendanceStatus.early;
    } else {
      status = AttendanceStatus.late;
    }

    // ✅ Validate late reason (MoEYI compliance)
    if (status == AttendanceStatus.late) {
      if (lateReason == null || lateReason.trim().isEmpty) {
        throw const LateReasonRequiredException();
      }

      // Validate that reason is a standard MoEYI category
      if (!MoEYILateReasonLabel.isValid(lateReason)) {
        throw InvalidLateReasonException(lateReason);
      }
    }

    final cleanedReason = lateReason?.trim();

    // ✅ Build AttendanceDay with shift information
    final day = AttendanceDay(
      dateKey: dateKey,
      studentUid: studentUid,
      status: status,
      schoolId: schoolId,
      classId: classId,
      className: className,
      gradeLevel: gradeLevel,
      shiftType: shiftType, // 🔥 Critical: Store shift on the document
      clockInAt: ts,
      clockInLocation: location,
      lateReason: (cleanedReason == null || cleanedReason.isEmpty)
          ? null
          : cleanedReason,
      source: AttendanceSource.studentSelf,
      deviceId: deviceId,
    );

    try {
      await _repo.saveDay(
        schoolId: schoolId,
        studentUid: studentUid,
        day: day,
        isNew: existing == null,
        changedByUid: studentUid, // Self clock-in
      );
      return day;
    } catch (e, st) {
      dev.log(
        'AttendanceService.clockIn failed: $e',
        name: 'AttendanceService.clockIn',
        error: e,
        stackTrace: st,
      );
      throw AttendancePersistenceException(
        'Failed to save clock-in record',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Student taps "Clock Out".
  ///
  /// **Flow:**
  /// 1. Validate school day (no weekend/holiday)
  /// 2. Determine shiftType for this student (currently always `whole_day`)
  /// 3. Load existing attendance record for this shift/day
  /// 4. Validate that clock-in exists and clock-out hasn't happened
  /// 5. Add clock-out timestamp and location
  /// 6. Classify as early-leave / overtime
  ///
  /// **Throws:**
  /// - [NotSchoolDayException] if weekend/holiday
  /// - [NoClockInFoundException] if no clock-in for this shift/day
  /// - [AlreadyClockedOutException] if already clocked out
  /// - [AttendancePersistenceException] on persistence errors
  ///
  /// **Returns:** The updated [AttendanceDay].
  Future<AttendanceDay> clockOut({
    required String schoolId,
    required String studentUid,
    required AttendanceLocation location,
    String? classId,
    String? className,
    int? gradeLevel,
    String? deviceId, // Device identifier for anti-fraud
    DateTime? at,
  }) async {
    final ts = at ?? schoolNow();
    final dateKey = AttendanceDay.dateKeyFor(ts);

    // ⛔️ Block weekends / public holidays
    if (!_isSchoolDay(ts)) {
      throw const NotSchoolDayException();
    }

    // Optional sanity check: ensure student profile exists.
    final student = await _userService.getUser(studentUid);
    if (student == null) {
      throw AttendancePersistenceException(
        'Student profile not found: $studentUid',
      );
    }

    // For now, default every student to whole_day.
    // When AppUser has currentShift/shiftType, derive it from [student].
    // Determine shift type (same logic as clock-in)
    final rawShift = student.currentShift;
    final shiftType = AttendanceDay.normalizeShiftType(rawShift);

    // ✅ Load existing day for this shift
    final existing = await _repo.getDay(
      schoolId: schoolId,
      studentUid: studentUid,
      dateKey: dateKey,
      shiftType: shiftType,
    );

    // ⛔️ Must have clocked in first
    if (existing == null || existing.clockInAt == null) {
      throw const NoClockInFoundException();
    }

    // ⛔️ Cannot clock out twice
    if (existing.clockOutAt != null) {
      throw const AlreadyClockedOutException();
    }

    //Shift-Aware end + service
    final classEnd = _classEndFor(ts, shiftType);
    final overtimeCutoff = _overtimeCutoffFor(ts, shiftType);

    // ✅ Classify this clock-out
    final isEarlyLeave = ts.isBefore(classEnd);
    final isOvertime = ts.isAfter(overtimeCutoff);

    if (isEarlyLeave) {
      dev.log(
        'Early leave detected | schoolId=$schoolId, uid=$studentUid, '
        'shift=$shiftType, date=$dateKey, clockOut=$ts',
        name: 'AttendanceService.clockOut',
      );
    } else if (isOvertime) {
      dev.log(
        'Overtime detected | schoolId=$schoolId, uid=$studentUid, '
        'shift=$shiftType, date=$dateKey, clockOut=$ts',
        name: 'AttendanceService.clockOut',
      );
    }

    // ✅ Update with clock-out data
    final updated = existing.copyWith(
      schoolId: schoolId,
      classId: classId ?? existing.classId,
      className: className ?? existing.className,
      gradeLevel: gradeLevel ?? existing.gradeLevel,
      clockOutAt: ts,
      clockOutLocation: location,
      isEarlyLeave: isEarlyLeave,
      isOvertime: isOvertime,
      source: AttendanceSource.studentSelf,
      deviceId: deviceId,
    );

    try {
      await _repo.saveDay(
        schoolId: schoolId,
        studentUid: studentUid,
        day: updated,
        isNew: false,
        changedByUid: studentUid, // Self clock-out
      );
      return updated;
    } catch (e, st) {
      dev.log(
        'AttendanceService.clockOut failed: $e',
        name: 'AttendanceService.clockOut',
        error: e,
        stackTrace: st,
      );
      throw AttendancePersistenceException(
        'Failed to save clock-out record',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Load today's attendance record for this student.
  ///
  /// **Shift behavior today:**
  /// - If [shiftType] is provided, that specific shift is used.
  /// - If [shiftType] is null, we default to `whole_day`.
  ///
  /// Returns `null` if no record exists for today's shift.
  Future<AttendanceDay?> getToday({
    required String schoolId,
    required String studentUid,
    String? shiftType,
    DateTime? at,
  }) async {
    final ts = at ?? schoolNow();
    final dateKey = AttendanceDay.dateKeyFor(ts);

    String effectiveShift;

    if (shiftType != null && shiftType.trim().isNotEmpty) {
      // If UI explicitly passes a shift, trust that
      effectiveShift = AttendanceDay.normalizeShiftType(shiftType);
    } else {
      // Otherwise, derive from the student profile (or default to whole_day)
      final student = await _userService.getUser(studentUid);

      final String? rawShift = student?.currentShift;
      effectiveShift = AttendanceDay.normalizeShiftType(rawShift);
    }

    return _repo.getDay(
      schoolId: schoolId,
      studentUid: studentUid,
      dateKey: dateKey,
      shiftType: effectiveShift,
    );
  }

  /// Load recent days (e.g., last 7 or 14) for history UI.
  ///
  /// **Shift behavior today:**
  /// - If [shiftType] is provided, fetches only records for that shift.
  /// - If [shiftType] is null, defaults to `whole_day` (non-shift schools).
  Future<List<AttendanceDay>> getRecentDays({
    required String schoolId,
    required String studentUid,
    int limit = 14,
    String? shiftType,
  }) {
    final effectiveShift = shiftType != null
        ? AttendanceDay.normalizeShiftType(shiftType)
        : AttendanceDay.defaultShiftType;

    return _repo.getRecentDays(
      schoolId: schoolId,
      studentUid: studentUid,
      limit: limit,
      shiftType: effectiveShift,
    );
  }

  /// Convenience wrapper for UI code.
  Future<List<AttendanceDay>> getRecentDaysForStudent({
    required String schoolId,
    required String studentUid,
    int limit = 14,
    String? shiftType,
  }) {
    return getRecentDays(
      schoolId: schoolId,
      studentUid: studentUid,
      limit: limit,
      shiftType: shiftType,
    );
  }
}
