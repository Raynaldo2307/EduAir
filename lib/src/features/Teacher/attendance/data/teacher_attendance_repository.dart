import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/teacher/attendance/data/teacher_attendance_data_source.dart';
import 'package:edu_air/src/features/teacher/attendance/domain/teacher_attendance_models.dart';

class TeacherAttendanceRepository {
  TeacherAttendanceRepository({TeacherAttendanceDataSource? remote})
      : _remote = remote ?? TeacherAttendanceDataSource();

  final TeacherAttendanceDataSource _remote;

  Future<List<TeacherAttendanceStudent>> getStudentsForClass({
    required String schoolId,
    required TeacherClassOption classOption,
  }) {
    return _remote.fetchStudentsForClass(
      schoolId: schoolId,
      classOption: classOption,
    );
  }

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

  Future<void> saveAttendanceBatch({
    required String schoolId,
    required List<TeacherAttendanceEntry> entries,
  }) {
    return _remote.commitAttendanceBatch(
      schoolId: schoolId,
      entries: entries,
    );
  }
}
