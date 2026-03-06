import 'package:dio/dio.dart';
import 'package:edu_air/src/services/api_client.dart';

/// Calls the Node.js attendance endpoints.
///
/// All school scoping comes from the JWT — no need to pass schoolId here.
class AttendanceApiRepository {
  final Dio _dio;

  AttendanceApiRepository({required ApiClient client}) : _dio = client.dio;

  /// GET /api/attendance?date=YYYY-MM-DD&shift_type=morning
  /// Returns all attendance records for a school on a given date + shift.
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

  /// GET /api/attendance/student/:studentId?limit=14&shift_type=morning
  /// Returns a student's attendance history.
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

  /// POST /api/attendance/clock-in
  /// Status (early/late) is resolved by the Node server using Jamaica time.
  Future<Map<String, dynamic>> clockIn({
    required int studentId,
    required String shiftType,
    required double lat,
    required double lng,
    String? lateReasonCode,
    String? deviceId,
  }) async {
    final response = await _dio.post(
      '/api/attendance/clock-in',
      data: {
        'student_id': studentId,
        'shift_type': shiftType,
        'clock_in_lat': lat,
        'clock_in_lng': lng,
        if (lateReasonCode != null) 'late_reason_code': lateReasonCode,
        if (deviceId != null) 'device_id': deviceId,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// PUT /api/attendance/:id/clock-out
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

  /// PUT /api/attendance/:id
  /// Admin/teacher corrects a record — writes audit trail on the server.
  Future<Map<String, dynamic>> updateRecord({
    required int attendanceId,
    required String status,
    String? note,
  }) async {
    final response = await _dio.put(
      '/api/attendance/$attendanceId',
      data: {
        'status': status,
        if (note != null) 'note': note,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// DELETE /api/attendance/:id — admin only, today's records only.
  Future<void> deleteRecord(int attendanceId) async {
    await _dio.delete('/api/attendance/$attendanceId');
  }
}
