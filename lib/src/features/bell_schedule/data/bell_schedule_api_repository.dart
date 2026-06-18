import 'package:dio/dio.dart';

import 'package:edu_air/src/services/api_client.dart';
import 'package:edu_air/src/features/bell_schedule/domain/shift.dart';
import 'package:edu_air/src/features/bell_schedule/domain/bell_period.dart';

/// Talks to /api/shifts and /api/bell-periods. school_id is enforced
/// server-side from the JWT — the client never sends it.
class BellScheduleApiRepository {
  final Dio _dio;

  BellScheduleApiRepository({required ApiClient client}) : _dio = client.dio;

  /// GET /api/shifts — this school's shifts (whole-day = one, multi-shift = many).
  Future<List<Shift>> getShifts() async {
    final res = await _dio.get('/api/shifts');
    final rows = List<Map<String, dynamic>>.from(res.data['data'] as List);
    return rows.map(Shift.fromMap).toList();
  }

  /// GET /api/bell-periods?shift_id=X — one shift's bell schedule, ordered.
  Future<List<BellPeriod>> getPeriods(int shiftId) async {
    final res = await _dio.get(
      '/api/bell-periods',
      queryParameters: {'shift_id': shiftId},
    );
    final rows = List<Map<String, dynamic>>.from(res.data['data'] as List);
    return rows.map(BellPeriod.fromMap).toList();
  }
}
