// lib/src/features/attendance/domain/attendance_models.dart

/// High-level status for one day of attendance.
///
/// 🔹 `early`  = present + clocked in between 08:00–08:30 (inclusive)
/// 🔹 `late`   = present + clocked in after 08:30
/// 🔹 `present`= manual present / remote case where you don't care about timing
/// 🔹 `absent` = no valid clock-in for this school day
enum AttendanceStatus {
  early,
  late,
  present,
  absent,
}

extension AttendanceStatusLabel on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.early:
        return 'Early';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
    }
  }

  /// Convenience: is the student considered present in school?
  bool get isPresentLike => this != AttendanceStatus.absent;
}

/// Simple location snapshot (no Firestore types here).
class AttendanceLocation {
  final double lat;
  final double lng;

  const AttendanceLocation({
    required this.lat,
    required this.lng,
  });
}

/// One day's attendance record for a student.
///
/// ✅ Design:
/// - `dateKey` is the school day, formatted as "YYYY-MM-DD" in the school's
///   timezone (e.g. America/Jamaica). Use [AttendanceDay.dateKeyFor] to build it.
/// - For `absent`, time/location fields SHOULD be null.
/// - For `early` / `late`, `clockInAt` SHOULD be non-null.
/// - For `present`, `clockInAt` MAY be null (manual present override).
class AttendanceDay {
  /// School day key, e.g. "2025-12-20" (normalized to school timezone).
  final String dateKey;

  /// The student's uid.
  final String studentUid;

  /// High-level status for that day.
  final AttendanceStatus status;

  /// When the student clocked in (local time).
  final DateTime? clockInAt;

  /// When the student clocked out (local time).
  final DateTime? clockOutAt;

  /// Where they were when clocking in.
  final AttendanceLocation? clockInLocation;

  /// Where they were when clocking out.
  final AttendanceLocation? clockOutLocation;

  /// Optional reason if late **or** note (e.g. excused absence).
  final String? lateReason;


  /// New: did the student leave before class end?
  final bool isEarlyLeave;

  /// New: did the student stay after the overtime cutoff?
  final bool isOvertime;

  /// Core constructor.
  ///
  /// Contains light-weight asserts to avoid obviously broken state.
  /// 
  const AttendanceDay({
    required this.dateKey,
    required this.studentUid,
    required this.status,
    this.clockInAt,
    this.clockOutAt,
    this.clockInLocation,
    this.clockOutLocation,
    this.lateReason,
    this.isEarlyLeave = false,   // 👈 NEW
    this.isOvertime = false,     
  })  : assert(
          // Absent: no times/locations; reason is allowed (excused absence).
          status != AttendanceStatus.absent ||
              (clockInAt == null &&
                  clockOutAt == null &&
                  clockInLocation == null &&
                  clockOutLocation == null),
          'Absent day $dateKey for $studentUid should not have clock-in/out data.',
        ),
        assert(
          // Early/late MUST have a clock-in time.
          status == AttendanceStatus.absent ||
              status == AttendanceStatus.present ||
              clockInAt != null,
          'Early/late day $dateKey for $studentUid must have clockInAt.',
        );

  /// Helper to build a "YYYY-MM-DD" key from a [DateTime].
  ///
  /// Call this from your service using the device/server time that is already
  /// normalized to the school timezone (e.g. America/Jamaica).
  static String dateKeyFor(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Copy with support for explicitly clearing nullable fields.
  ///
  /// For nullable fields we use a private sentinel so you can:
  /// - omit the param → keep old value
  /// - pass `null`    → explicitly clear it
  AttendanceDay copyWith({
    String? dateKey,
    String? studentUid,
    AttendanceStatus? status,

    Object? clockInAt = _sentinel,
    Object? clockOutAt = _sentinel,
    Object? clockInLocation = _sentinel,
    Object? clockOutLocation = _sentinel,
    Object? lateReason = _sentinel,
    bool? isEarlyLeave,
    bool? isOvertime,
  }) {
    return AttendanceDay(
      dateKey: dateKey ?? this.dateKey,
      studentUid: studentUid ?? this.studentUid,
      status: status ?? this.status,
      clockInAt: identical(clockInAt, _sentinel)
          ? this.clockInAt
          : clockInAt as DateTime?,
      clockOutAt: identical(clockOutAt, _sentinel)
          ? this.clockOutAt
          : clockOutAt as DateTime?,
      clockInLocation: identical(clockInLocation, _sentinel)
          ? this.clockInLocation
          : clockInLocation as AttendanceLocation?,
      clockOutLocation: identical(clockOutLocation, _sentinel)
          ? this.clockOutLocation
          : clockOutLocation as AttendanceLocation?,
      lateReason: identical(lateReason, _sentinel)
          ? this.lateReason
          : lateReason as String?,
           isEarlyLeave: isEarlyLeave ?? this.isEarlyLeave,  // 👈 NEW
      isOvertime: isOvertime ?? this.isOvertime,        // 👈 NEW
    );
  }
    

  /// Simple helper: is this day tagged as late?
  ///
  /// (Uses the stored status; the decision should come from [resolveStatusFromClockIn].)
  bool get isLate => status == AttendanceStatus.late;

  /// Shared helper to decide `early` vs `late` from a clock-in time.
  ///
  /// Rules (Jamaica school context):
  /// - Class start:        08:00
  /// - Grace period:       30 minutes
  /// - Early window:       [08:00, 08:30] (inclusive)
  /// - Late window:        > 08:30 up to end of school day
  ///
  /// Usage (in your service):
  /// ```dart
  /// final status = AttendanceDay.resolveStatusFromClockIn(
  ///   clockIn: now,
  ///   classStart: DateTime(... 8, 0),
  ///   grace: const Duration(minutes: 30),
  /// );
  /// ```
  static AttendanceStatus resolveStatusFromClockIn({
    required DateTime clockIn,
    required DateTime classStart,
    required Duration grace,
  }) {
    final cutoff = classStart.add(grace);

    // If you ever enable clock-in before classStart, this treats ait as early too.
    if (clockIn.isBefore(cutoff) || clockIn.isAtSameMomentAs(cutoff)) {
      return AttendanceStatus.early;
    }
    return AttendanceStatus.late;
  }
}

// Private sentinel for copyWith.
const Object _sentinel = Object();
