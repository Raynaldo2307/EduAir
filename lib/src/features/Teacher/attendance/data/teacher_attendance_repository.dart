import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/teacher/attendance/data/teacher_attendance_data_source.dart';
import 'package:edu_air/src/features/teacher/attendance/domain/teacher_attendance_models.dart';

/// TeacherAttendanceRepository
/// ---------------------------
/// Single entry point for teacher-driven attendance.
///
/// Responsibilities:
/// - Expose simple, role-friendly methods to the UI / services:
///   - getStudentsForClass
///   - getAttendanceForDate
///   - saveAttendanceBatch (with a rich result for offline / flaky network)
///   - getMonthlyClassSummary (SF4-friendly aggregation)
///
/// It delegates all Firestore details to [TeacherAttendanceDataSource].
class TeacherAttendanceRepository {
  TeacherAttendanceRepository({required TeacherAttendanceDataSource remote})
      : _remote = remote;

  final TeacherAttendanceDataSource _remote;

  /// Returns all students in the given class for a school,
  /// mapped to domain model [TeacherAttendanceStudent].
  Future<List<TeacherAttendanceStudent>> getStudentsForClass({
    required String schoolId,
    required TeacherClassOption classOption,
  }) {
    return _remote.fetchStudentsForClass(
      schoolId: schoolId,
      classOption: classOption,
    );
  }

  /// Returns a map of studentUid -> AttendanceStatus for a given
  /// school + class + date (+ optional shift).
  ///
  /// Used to pre-fill the teacher roll screen so existing marks
  /// are shown as Present/Absent/Late/Excused.
  Future<Map<String, AttendanceStatus>> getAttendanceForDate({
    required String schoolId,
    required TeacherClassOption classOption,
    required String dateKey,
    String? shiftType,
  }) {
    return _remote.fetchAttendanceForClassDate(
      schoolId: schoolId,
      classOption: classOption,
      dateKey: dateKey,
      shiftType: shiftType,
    );
  }

  /// Save a teacher's roll-call for a class as a Firestore batch.
  ///
  /// Returns [AttendanceBatchResult], so the UI can:
  /// - detect full success vs total failure in low-connectivity scenarios.
  Future<AttendanceBatchResult> saveAttendanceBatch({
    required String schoolId,
    required List<TeacherAttendanceEntry> entries,
  }) {
    return _remote.saveAttendanceBatch(
      schoolId: schoolId,
      entries: entries,
    );
  }

  /// Aggregated monthly summary for SF4-style reporting:
  /// - total marked records
  /// - total present-like (early/late/present)
  /// - total absent
  /// - total excused
  /// - total distinct school days in that month
  /// - average daily attendance
  /// - percentage attendance for the month.
  ///
  /// This is per school + class (+ optional shiftType) and per year/month.
  Future<ClassMonthlyAttendanceSummary> getMonthlyClassSummary({
    required String schoolId,
    required TeacherClassOption classOption,
    required int year,
    required int month,
    String? shiftType,
  }) {
    return _remote.fetchMonthlyClassSummary(
      schoolId: schoolId,
      classOption: classOption,
      year: year,
      month: month,
      shiftType: shiftType,
    );
  }
}