// lib/src/features/attendance/domain/attendance_models.dart

/// High-level status for one day of attendance.
///
/// 🔹 `early`  = present + clocked in between 08:00–08:30 (inclusive)
/// 🔹 `late`   = present + clocked in after 08:30
/// 🔹 `present`= manual present / remote case where you don't care about timing
/// 🔹 `absent` = no valid clock-in for this school day
enum AttendanceStatus { early, late, present, absent, excused }

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
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  /// Convenience: is the student considered present in school?
  bool get isPresentLike =>
      this == AttendanceStatus.early ||
      this == AttendanceStatus.late ||
      this == AttendanceStatus.present;
}

/// MoEYI (Ministry of Education, Youth & Information) standardized late reason categories.
///
/// Used for:
/// - Form SF4 attendance reporting (Jamaican schools)
/// - AI behavioral analysis
/// - Data Protection Act 2020 compliance (authentic, categorized records)
///
/// Students must select one of these categories when clocking in late.
/// Free-text is not permitted to ensure data quality for government reporting.
enum MoEYILateReason {
  transportation,
  economic,
  illness,
  emergency,
  family,
  other,
}

extension MoEYILateReasonLabel on MoEYILateReason {
  String get label {
    switch (this) {
      case MoEYILateReason.transportation:
        return 'Transportation';
      case MoEYILateReason.economic:
        return 'Economic';
      case MoEYILateReason.illness:
        return 'Illness';
      case MoEYILateReason.emergency:
        return 'Emergency';
      case MoEYILateReason.family:
        return 'Family';
      case MoEYILateReason.other:
        return 'Other';
    }
  }

  /// Get the category code for Firestore storage.
  String get code => name;

  /// Parse a stored code back to enum value.
  static MoEYILateReason? fromCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final normalized = code.trim().toLowerCase();

    return MoEYILateReason.values.firstWhere(
      (reason) => reason.code == normalized,
      orElse: () => MoEYILateReason.other,
    );
  }

  /// Validate if a string is a valid MoEYI reason code.
  static bool isValid(String? code) {
    if (code == null || code.trim().isEmpty) return false;
    final normalized = code.trim().toLowerCase();
    return MoEYILateReason.values.any((reason) => reason.code == normalized);
  }
}

/// Simple location snapshot (no Firestore types here).
class AttendanceLocation {
  final double lat;
  final double lng;

  const AttendanceLocation({required this.lat, required this.lng});
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
  static const String defaultShiftType = 'whole_day';
  static const Set<String> validShiftTypes = {
    'morning',
    'afternoon',
    'whole_day',
  };

  /// School day key, e.g. "2025-12-20" (normalized to school timezone).
  final String dateKey;

  /// The student's uid.
  final String studentUid;

  /// Multi-tenant anchor.
  final String? schoolId;

  /// Class/form context (homeroom or subject attendance).
  final String? classId;
  final String? className;
  final int? gradeLevel;
  final String? sex;

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

  /// Teacher/auditor fields (for homeroom roll).
  final String? takenByUid;
  final DateTime? takenAt;
  final DateTime? updatedAt;

  /// Optional subject fields (lesson attendance).
  final String? subjectId;
  final String? subjectName;
  final String? periodId;

  /// Optional shift (Jamaican shift systems).
  final String? shiftType;

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
    this.schoolId,
    this.classId,
    this.className,
    this.gradeLevel,
    this.sex,
    this.clockInAt,
    this.clockOutAt,
    this.clockInLocation,
    this.clockOutLocation,
    this.lateReason,
    this.takenByUid,
    this.takenAt,
    this.updatedAt,
    this.subjectId,
    this.subjectName,
    this.periodId,
    this.shiftType,
    this.isEarlyLeave = false, // 👈 NEW
    this.isOvertime = false,
  }) : assert(
         // Absent: no times/locations; reason is allowed (excused absence).
         (status != AttendanceStatus.absent &&
                 status != AttendanceStatus.excused) ||
             (clockInAt == null &&
                 clockOutAt == null &&
                 clockInLocation == null &&
                 clockOutLocation == null),
         'Absent day $dateKey for $studentUid should not have clock-in/out data.',
       ),
       assert(
         // Early/late MUST have a clock-in time.
         status == AttendanceStatus.absent ||
             status == AttendanceStatus.excused ||
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

  static String normalizeShiftType(String? shiftType) {
    final shiftInput = (shiftType ?? '').trim();
    if (shiftInput.isEmpty) return defaultShiftType;

    final lower = shiftInput.toLowerCase();

    // Accept some aliases
    if (lower == 'evening') return 'afternoon';
    if (lower == 'am' || lower == 'morning') return 'morning';
    if (lower == 'pm' || lower == 'afternoon') return 'afternoon';
    if (lower == 'whole_day' || lower == 'wholeday' || lower == 'full_day') {
      return 'whole_day';
    }

    // If it’s already one of the canonical values, keep it
    if (validShiftTypes.contains(lower)) return lower;

    // Fallback
    return defaultShiftType;
  }

  static String docIdFor({
    required String dateKey,
    required String shiftType,
    required String studentUid,
  }) {
    final effectiveShiftType = normalizeShiftType(shiftType);
    return '${dateKey}_${effectiveShiftType}_$studentUid';
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

    Object? schoolId = _sentinel,
    Object? classId = _sentinel,
    Object? className = _sentinel,        /*
                                         

	4.	teacher_attendance_models.dart
	5.	teacher_attendance_data_source.dart
	6.	teacher_attendance_repository.dart

                                           */
    Object? gradeLevel = _sentinel,
    Object? sex = _sentinel,

    Object? clockInAt = _sentinel,
    Object? clockOutAt = _sentinel,
    Object? clockInLocation = _sentinel,
    Object? clockOutLocation = _sentinel,
    Object? lateReason = _sentinel,
    Object? takenByUid = _sentinel,
    Object? takenAt = _sentinel,
    Object? updatedAt = _sentinel,
    Object? subjectId = _sentinel,
    Object? subjectName = _sentinel,
    Object? periodId = _sentinel,
    Object? shiftType = _sentinel,
    bool? isEarlyLeave,
    bool? isOvertime,
  }) {
    return AttendanceDay(
      dateKey: dateKey ?? this.dateKey,
      studentUid: studentUid ?? this.studentUid,
      status: status ?? this.status,
      schoolId: identical(schoolId, _sentinel)
          ? this.schoolId
          : schoolId as String?,
      classId: identical(classId, _sentinel)
          ? this.classId
          : classId as String?,
      className: identical(className, _sentinel)
          ? this.className
          : className as String?,
      gradeLevel: identical(gradeLevel, _sentinel)
          ? this.gradeLevel
          : gradeLevel as int?,
      sex: identical(sex, _sentinel) ? this.sex : sex as String?,
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
      takenByUid: identical(takenByUid, _sentinel)
          ? this.takenByUid
          : takenByUid as String?,
      takenAt: identical(takenAt, _sentinel)
          ? this.takenAt
          : takenAt as DateTime?,
      updatedAt: identical(updatedAt, _sentinel)
          ? this.updatedAt
          : updatedAt as DateTime?,
      subjectId: identical(subjectId, _sentinel)
          ? this.subjectId
          : subjectId as String?,
      subjectName: identical(subjectName, _sentinel)
          ? this.subjectName
          : subjectName as String?,
      periodId: identical(periodId, _sentinel)
          ? this.periodId
          : periodId as String?,
      shiftType: identical(shiftType, _sentinel)
          ? this.shiftType
          : shiftType as String?,
      isEarlyLeave: isEarlyLeave ?? this.isEarlyLeave, // 👈 NEW
      isOvertime: isOvertime ?? this.isOvertime, // 👈 NEW
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
