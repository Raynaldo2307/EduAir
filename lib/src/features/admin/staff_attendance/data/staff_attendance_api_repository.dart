import 'package:dio/dio.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_exceptions.dart';
import 'package:edu_air/src/services/api_client.dart';

class StaffAttendanceApiRepository {
  final Dio _dio;

  StaffAttendanceApiRepository(ApiClient client) : _dio = client.dio;

  /// GET /api/staff-attendance?date=YYYY-MM-DD
  /// Returns all active staff with their status for the given date.
  Future<List<Map<String, dynamic>>> getForDate(String date) async {
    final response = await _dio.get('/api/staff-attendance', queryParameters: {'date': date});
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  /// POST /api/staff-attendance/batch
  /// Upserts attendance for one or more staff members.
  Future<void> batchMark({
    required String date,
    required List<Map<String, dynamic>> records,
  }) async {
    await _dio.post('/api/staff-attendance/batch', data: {
      'date':    date,
      'records': records,
    });
  }

  // ── Self clock-in/out — the teacher clocks THEMSELVES (mirrors the student
  //    flow: server is the only judge of late; the phone never decides). ──

  /// GET /api/staff-attendance/today — the logged-in staff member's record
  /// for today, or null if they haven't clocked in / been marked yet.
  Future<Map<String, dynamic>?> getMyToday() async {
    final response = await _dio.get('/api/staff-attendance/today');
    return response.data['data'] as Map<String, dynamic>?;
  }

  /// POST /api/staff-attendance/clock-in — submit with NO reason first; if
  /// the server judges it late it answers 400 + code LATE_REASON_REQUIRED
  /// (nothing written yet), we throw the typed [LateReasonRequiredException],
  /// the UI shows the MoEYI dialog and resubmits with the chosen reason.
  Future<Map<String, dynamic>> clockIn({
    required double lat,
    required double lng,
    String? lateReasonCode,
  }) async {
    try {
      final response = await _dio.post('/api/staff-attendance/clock-in', data: {
        'clock_in_lat': lat,
        'clock_in_lng': lng,
        if (lateReasonCode != null) 'late_reason_code': lateReasonCode,
      });
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      // Match on the machine-readable code, never the message text.
      final data = e.response?.data;
      if (data is Map && data['code'] == 'LATE_REASON_REQUIRED') {
        throw const LateReasonRequiredException();
      }
      rethrow;
    }
  }

  /// GET /api/staff-attendance/me?limit=N — my own recent records, newest
  /// first. Feeds the teacher's calendar + summary counts.
  Future<List<Map<String, dynamic>>> getMyHistory({int limit = 90}) async {
    final response = await _dio.get(
      '/api/staff-attendance/me',
      queryParameters: {'limit': limit},
    );
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  /// PUT /api/staff-attendance/:id/clock-out — uses the row id from today's
  /// record; the server verifies the caller owns it and computes early-leave
  /// against the school's dismiss time.
  Future<Map<String, dynamic>> clockOut({
    required int attendanceId,
    required double lat,
    required double lng,
  }) async {
    final response = await _dio.put(
      '/api/staff-attendance/$attendanceId/clock-out',
      data: {'clock_out_lat': lat, 'clock_out_lng': lng},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
