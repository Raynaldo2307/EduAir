import 'package:dio/dio.dart';
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
}
