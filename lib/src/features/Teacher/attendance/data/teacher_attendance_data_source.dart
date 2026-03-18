import 'package:dio/dio.dart';

import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/teacher/attendance/domain/teacher_attendance_models.dart';
import 'package:edu_air/src/services/api_client.dart';

/// HTTP data source for teacher-driven attendance.
///
/// Replaces the previous Firestore implementation.
/// All data now lives in the Node.js / MySQL backend.
class TeacherAttendanceDataSource {
  TeacherAttendanceDataSource({required ApiClient client})
      : _dio = client.dio;

  final Dio _dio;

  /// GET /api/students?class_id={classOption.classId}
  ///
  /// Returns all active students in the selected class.
  Future<List<TeacherAttendanceStudent>> fetchStudentsForClass({
    required String schoolId,
    required TeacherClassOption classOption,
  }) async {
    final response = await _dio.get(
      '/api/students',
      queryParameters: {'class_id': classOption.classId},
    );
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => TeacherAttendanceStudent.fromApiJson(
              Map<String, dynamic>.from(json as Map),
            ))
        .toList();
  }

  /// GET /api/attendance?date=&class_id=&shift_type=
  ///
  /// Returns a map of studentId → AttendanceStatus for pre-filling the roll.
  Future<Map<String, AttendanceStatus>> fetchAttendanceForClassDate({
    required String schoolId,
    required TeacherClassOption classOption,
    required String dateKey,
    String? shiftType,
  }) async {
    final params = <String, dynamic>{
      'date':     dateKey,
      'class_id': classOption.classId,
    };
    final effectiveShift = AttendanceDay.normalizeShiftType(shiftType);
    params['shift_type'] = effectiveShift;

    final response = await _dio.get('/api/attendance', queryParameters: params);
    final data = response.data['data'] as List<dynamic>;

    final result = <String, AttendanceStatus>{};
    for (final item in data) {
      final studentId = (item['student_id'] ?? '').toString();
      if (studentId.isEmpty) continue;
      result[studentId] = _statusFromString(item['status'] as String?);
    }
    return result;
  }

  /// POST /api/attendance/batch
  ///
  /// Saves the whole roll for a class in one request.
  /// Upserts on the server — safe to call multiple times for the same date.
  Future<AttendanceBatchResult> saveAttendanceBatch({
    required String schoolId,
    required List<TeacherAttendanceEntry> entries,
  }) async {
    if (entries.isEmpty) {
      return const AttendanceBatchResult(
        totalEntries: 0,
        successCount: 0,
        failureCount: 0,
        failedStudentUids: [],
      );
    }

    final entriesJson = entries.map((e) {
      return <String, dynamic>{
        'student_id': int.tryParse(e.student.uid) ?? e.student.uid,
        'status':     e.status.name,
      };
    }).toList();

    try {
      await _dio.post('/api/attendance/batch', data: {
        'date':       entries.first.dateKey,
        'shift_type': entries.first.resolvedShiftType,
        'entries':    entriesJson,
      });

      return AttendanceBatchResult(
        totalEntries:      entries.length,
        successCount:      entries.length,
        failureCount:      0,
        failedStudentUids: const [],
      );
    } catch (_) {
      final failedUids = entries.map((e) => e.student.uid).toList();
      return AttendanceBatchResult(
        totalEntries:      entries.length,
        successCount:      0,
        failureCount:      entries.length,
        failedStudentUids: failedUids,
      );
    }
  }

  /// Monthly summary — stub for now (not required for capstone scope).
  Future<ClassMonthlyAttendanceSummary> fetchMonthlyClassSummary({
    required String schoolId,
    required TeacherClassOption classOption,
    required int year,
    required int month,
    String? shiftType,
  }) async {
    return ClassMonthlyAttendanceSummary(
      schoolId:            schoolId,
      classOption:         classOption,
      year:                year,
      month:               month,
      shiftType:           shiftType ?? 'whole_day',
      totalMarkedRecords:  0,
      totalPresentLike:    0,
      totalAbsent:         0,
      totalExcused:        0,
      distinctSchoolDays:  0,
    );
  }

  AttendanceStatus _statusFromString(String? value) {
    if (value == null || value.isEmpty) return AttendanceStatus.present;
    for (final status in AttendanceStatus.values) {
      if (status.name == value) return status;
    }
    return AttendanceStatus.present;
  }
}
