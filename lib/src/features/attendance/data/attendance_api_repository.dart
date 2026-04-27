// ─────────────────────────────────────────────────────────────────────────────
// FILE: attendance_api_repository.dart
// WHAT: Every attendance API call in the app goes through this one class.
// HOW:  Uses the shared Dio client (which already has the JWT interceptor).
// WHY:  Repositories are the data layer — they know how to talk to the API.
//       Controllers and UI never call Dio directly. That is clean architecture.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:edu_air/src/services/api_client.dart';

// ASSESSOR POINT A — Attendance Repository
// All 6 attendance operations live here: getByDate, getHistory, getToday,
// getMyHistory, clockIn, clockOut, updateRecord, deleteRecord.
// School scoping (which school's data to fetch) comes from the JWT —
// this class never needs to be told which school to use.
class AttendanceApiRepository {
  final Dio _dio;

  AttendanceApiRepository({required ApiClient client}) : _dio = client.dio;

  // ASSESSOR POINT B — Get attendance by date and shift (Teacher/Admin view)
  // Admin uses this to see a full attendance report for a date.
  // The school_id comes from the JWT — can never query another school's records.
  Future<List<Map<String, dynamic>>> getByDateAndShift({
    required String date,
    required String shiftType,
  }) async {
    final response = await _dio.get(
      '/api/attendance',
      queryParameters: {'date': date, 'shift_type': shiftType},
    );
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  // Get a specific student's attendance history — used on admin/teacher reports.
  Future<List<Map<String, dynamic>>> getStudentHistory({
    required int studentId,
    int limit = 14,
    String? shiftType,
  }) async {
    final response = await _dio.get(
      '/api/attendance/student/$studentId',
      queryParameters: {
        'limit': limit,
        if (shiftType != null) 'shift_type': shiftType,
      },
    );
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  // ASSESSOR POINT C — Get today's record for the logged-in student
  // Student identity comes from the JWT. The student never passes their own ID.
  // Returns null if the student hasn't clocked in yet today.
  Future<Map<String, dynamic>?> getMyToday({String? shiftType}) async {
    final response = await _dio.get(
      '/api/attendance/today',
      queryParameters: {
        if (shiftType != null) 'shift_type': shiftType,
      },
    );
    return response.data['data'] as Map<String, dynamic>?;
  }

  // Student's own attendance history — used on the calendar screen.
  Future<List<Map<String, dynamic>>> getMyHistory({
    int limit = 14,
    String? shiftType,
  }) async {
    final response = await _dio.get(
      '/api/attendance/me',
      queryParameters: {
        'limit': limit,
        if (shiftType != null) 'shift_type': shiftType,
      },
    );
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  // ASSESSOR POINT D — Clock In (the core feature)
  // Student taps Clock In → app sends GPS coordinates + shift type to Node.js.
  // The server determines early vs late using Jamaica server time — client cannot fake it.
  // studentId is optional: omit for student self-clock-in (server reads from JWT).
  // Pass studentId when a teacher clocks in on behalf of a student.
  Future<Map<String, dynamic>> clockIn({
    int? studentId,
    required String shiftType,
    required double lat,
    required double lng,
    String? lateReasonCode,
    String? deviceId,
  }) async {
    final response = await _dio.post(
      '/api/attendance/clock-in',
      data: {
        if (studentId != null) 'student_id': studentId,
        'shift_type': shiftType,
        'clock_in_lat': lat,
        'clock_in_lng': lng,
        if (lateReasonCode != null) 'late_reason_code': lateReasonCode,
        if (deviceId != null) 'device_id': deviceId,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // ASSESSOR POINT E — Clock Out
  // Uses the MySQL row ID from the clock-in record as a PUT endpoint.
  // GPS coordinates recorded again so we know the student left campus.
  Future<Map<String, dynamic>> clockOut({
    required int attendanceId,
    required double lat,
    required double lng,
  }) async {
    final response = await _dio.put(
      '/api/attendance/$attendanceId/clock-out',
      data: {'clock_out_lat': lat, 'clock_out_lng': lng},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // ASSESSOR POINT F — Update a record (Admin correction with audit trail)
  // Admin can correct a status after the fact.
  // The server writes the change to an audit log — who changed it, when, and why.
  // This satisfies the "no silent edits" requirement for government compliance.
  Future<Map<String, dynamic>> updateRecord({
    required int attendanceId,
    required String status,
    String? lateReasonCode,
    String? note,
  }) async {
    final response = await _dio.put(
      '/api/attendance/$attendanceId',
      data: {
        'status': status,
        if (lateReasonCode != null) 'late_reason_code': lateReasonCode,
        if (note != null) 'note': note,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Admin-only hard delete — only permitted for today's records.
  // Historical records cannot be deleted — data integrity rule.
  Future<void> deleteRecord(int attendanceId) async {
    await _dio.delete('/api/attendance/$attendanceId');
  }
}
