import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/models/app_user.dart';

/// Represents a specific class/form a teacher can take attendance for.
///
/// Examples:
/// - classId: "7B_2025"
/// - className: "7th B"
class TeacherClassOption {
  const TeacherClassOption({
    required this.classId,
    required this.className,
    this.gradeLevel,
  });

  /// Stable internal identifier (can encode year/stream if you want).
  final String classId;

  /// Human-readable label, e.g. "7th B".
  final String className;

  /// Optional numeric grade level (1–6 primary, 7–13 high school).
  final int? gradeLevel;

  @override
  bool operator ==(Object other) {
    return other is TeacherClassOption &&
        other.classId == classId &&
        other.className == className;
  }

  @override
  int get hashCode => Object.hash(classId, className);
}

/// Projection of a student row for the teacher attendance screen.
class TeacherAttendanceStudent {
  const TeacherAttendanceStudent({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.classId,
    this.className,
    this.gradeLevel,
    this.sex,
  });

  /// Student UID (same as AppUser.uid).
  final String uid;

  /// Display name shown in the UI.
  final String displayName;

  /// Optional avatar URL.
  final String? photoUrl;

  /// Class/form ID the student currently belongs to.
  final String? classId;

  /// Human-readable class/form name (e.g. "7th B").
  final String? className;

  /// Numeric grade level, if known.
  final int? gradeLevel;

  /// Sex/gender (expected "M" or "F" after normalization).
  final String? sex;

  /// First letter of the student's name, for fallback avatars.
  String get initials {
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) return 'U';
    return trimmedName.substring(0, 1).toUpperCase();
  }

  /// Build from the core [AppUser] model.
  factory TeacherAttendanceStudent.fromUser(AppUser user) {
    return TeacherAttendanceStudent(
      uid: user.uid,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      classId: user.classId,
      className: user.className,
      gradeLevel: user.gradeLevelNumber,
      sex: user.sex ?? user.gender,
    );
  }
}

/// One row in the teacher's roll for a single student on a specific day.
///
/// This is what the UI builds when the teacher taps "Save Attendance".
class TeacherAttendanceEntry {
  TeacherAttendanceEntry({
    required this.schoolId,
    required this.dateKey,
    required this.status,
    required this.student,
    required this.classOption,
    required this.takenByUid,
    this.shiftType,
    this.subjectId,
    this.subjectName,
    this.periodId,
  });

  /// School this attendance belongs to (multi-tenant anchor).
  final String schoolId;

  /// School day key "YYYY-MM-DD".
  final String dateKey;

  /// Attendance status chosen by the teacher.
  final AttendanceStatus status;

  /// Student being marked present/absent/late/excused.
  final TeacherAttendanceStudent student;

  /// Class/form context the teacher selected.
  final TeacherClassOption classOption;

  /// UID of the teacher who took/updated this roll.
  final String takenByUid;

  /// Shift type ("morning", "afternoon", "evening", "whole_day").
  final String? shiftType;

  /// Optional subject metadata (for lesson-level attendance, v2).
  final String? subjectId;
  final String? subjectName;
  final String? periodId;

  /// Normalized shift type using [AttendanceDay.normalizeShiftType].
  String get resolvedShiftType => AttendanceDay.normalizeShiftType(shiftType);

  /// Deterministic Firestore document ID for this student + day + shift.
  ///
  /// Format:
  ///   {dateKey}_{shiftType}_{studentUid}
  String get docId => AttendanceDay.docIdFor(
    dateKey: dateKey,
    shiftType: resolvedShiftType,
    studentUid: student.uid,
  );

  /// Prefer the student's own classId, fall back to the teacher's selected class.
  String get resolvedClassId =>
      (student.classId != null && student.classId!.isNotEmpty)
      ? student.classId!
      : classOption.classId;

  /// Prefer the student's own className, fall back to the teacher's selected class.
  String get resolvedClassName =>
      (student.className != null && student.className!.isNotEmpty)
      ? student.className!
      : classOption.className;

  /// Prefer the student's own gradeLevel, else the classOption's gradeLevel.
  int? get resolvedGradeLevel => student.gradeLevel ?? classOption.gradeLevel;

  /// Normalized sex for stamping onto attendance docs.
  ///
  /// Returns "M" or "F" when possible, otherwise null.
  String? get resolvedSex {
    final sexSource = student.sex?.trim();
    if (sexSource == null || sexSource.isEmpty) return null;
    return sexSource.toUpperCase();
  }

  /// Convert to a Firestore-ready map (without timestamps).
  ///
  /// The data sources (Firestore layer) will add:
  /// - takenAt / updatedAt (serverTimestamp)
  /// - audit history entries
  Map<String, dynamic> toFirestoreMap() {
    return {
      'schoolId': schoolId,
      'studentUid': student.uid,
      'classId': resolvedClassId,
      'className': resolvedClassName,
      if (resolvedGradeLevel != null) 'gradeLevel': resolvedGradeLevel,
      if (resolvedSex != null) 'sex': resolvedSex,
      'date': dateKey,
      'status': status.name,
      'takenByUid': takenByUid,
      if (subjectId != null) 'subjectId': subjectId,
      if (subjectName != null) 'subjectName': subjectName,
      if (periodId != null) 'periodId': periodId,
      'shiftType': resolvedShiftType,
    };
  }
}

/// Result of a teacher attendance batch write.
///
/// Even though Firestore batches are all-or-nothing, this model gives
/// us room to:
/// - expose a clear success/failure signal to the UI
/// - later support partial/local validation failures in low-connectivity flows.
class AttendanceBatchResult {
  const AttendanceBatchResult({
    required this.totalEntries,
    required this.successCount,
    required this.failureCount,
    required this.failedStudentUids,
  });

  /// Number of entries the teacher tried to save in this operation.
  final int totalEntries;

  /// How many entries were successfully applied (for now, likely == totalEntries
  /// when Firestore commit succeeds).
  final int successCount;

  /// How many entries failed validation or could not be applied.
  final int failureCount;

  /// Student UIDs corresponding to failed entries (for "retry" UX).
  final List<String> failedStudentUids;

  /// True when everything in the batch was saved successfully.
  bool get isAllSuccessful => failureCount == 0;
}

/// Aggregated monthly summary for one class / shift.
///
/// This is the foundation for:
/// - MoEYI Form SF4 reporting (daily averages, percentage attendance),
/// - AI-driven early-warning signals (declining attendance patterns).
/// Aggregated monthly attendance summary for one class/form.
///
/// Designed to support Jamaican SF4-style reporting and AI analytics.
class ClassMonthlyAttendanceSummary {
  const ClassMonthlyAttendanceSummary({
    required this.schoolId,
    required this.classOption,
    required this.year,
    required this.month,
    required this.shiftType,
    required this.totalMarkedRecords,
    required this.totalPresentLike,
    required this.totalAbsent,
    required this.totalExcused,
    required this.distinctSchoolDays,
  });

  final String schoolId;
  final TeacherClassOption classOption;
  final int year;
  final int month;
  final String shiftType;

  /// Number of attendance records in this month for this class+shift.
  final int totalMarkedRecords;

  /// present + early + late
  final int totalPresentLike;

  final int totalAbsent;
  final int totalExcused;

  /// Number of distinct `date` values where attendance exists
  /// (effective school days for this class/shift).
  final int distinctSchoolDays;

  /// Average number of present-like students per school day.
  double get averageDailyAttendance {
    if (distinctSchoolDays == 0) return 0;
    return totalPresentLike / distinctSchoolDays;
  }

  /// Percentage of present-like records over all marks in the month.
  double get percentageAttendance {
    if (totalMarkedRecords == 0) return 0;
    return (totalPresentLike / totalMarkedRecords) * 100.0;
  }
}