import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/teacher/attendance/data/teacher_attendance_repository.dart';
import 'package:edu_air/src/features/teacher/attendance/domain/teacher_attendance_models.dart';
import 'package:edu_air/src/features/teacher/attendance/data/teacher_attendance_data_source.dart';

/// Repository provider – central access point for teacher attendance data.
final teacherAttendanceRepositoryProvider =
    Provider<TeacherAttendanceRepository>((ref) {
      final remote = TeacherAttendanceDataSource(
        client: ref.read(apiClientProvider),
      );
      return TeacherAttendanceRepository(remote: remote);
    });

/// Query key for "which students are in this class at this school?"
class TeacherClassQuery {
  const TeacherClassQuery({required this.schoolId, required this.classOption});

  final String schoolId;
  final TeacherClassOption classOption;

  @override
  bool operator ==(Object other) {
    return other is TeacherClassQuery &&
        other.schoolId == schoolId &&
        other.classOption == classOption; // 👈 reuse TeacherClassOption.==
  }

  @override
  int get hashCode => Object.hash(schoolId, classOption);
}

/// Query key for "what's the attendance map for this class on this date (and shift)?"
class TeacherAttendanceQuery {
  const TeacherAttendanceQuery({
    required this.schoolId,
    required this.classOption,
    required this.dateKey,
    this.shiftType,
  });

  final String schoolId;
  final TeacherClassOption classOption;
  final String dateKey;
  final String? shiftType;

  @override
  bool operator ==(Object other) {
    return other is TeacherAttendanceQuery &&
        other.schoolId == schoolId &&
        other.classOption == classOption && // 👈 reuse TeacherClassOption.==
        other.dateKey == dateKey &&
        other.shiftType == shiftType;
  }

  @override
  int get hashCode => Object.hash(schoolId, classOption, dateKey, shiftType);
}

/// Loads the list of students for a given (school, class) combination.
final teacherClassStudentsProvider = FutureProvider.family
    .autoDispose<List<TeacherAttendanceStudent>, TeacherClassQuery>((
      ref,
      query,
    ) async {
      final repo = ref.read(teacherAttendanceRepositoryProvider);
      return repo.getStudentsForClass(
        schoolId: query.schoolId,
        classOption: query.classOption,
      );
    });

/// Loads the attendance status map for a given (school, class, date, shift).
///
/// Returns:
///   `Map<studentUid, AttendanceStatus>`
final teacherAttendanceForDateProvider = FutureProvider.family
    .autoDispose<Map<String, AttendanceStatus>, TeacherAttendanceQuery>((
      ref,
      query,
    ) async {
      final repo = ref.read(teacherAttendanceRepositoryProvider);
      return repo.getAttendanceForDate(
        schoolId: query.schoolId,
        classOption: query.classOption,
        dateKey: query.dateKey,
        shiftType: query.shiftType,
      );
    });
