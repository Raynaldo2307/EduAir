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

  /// POST /api/schools/me/operating-model — set this school's operating model
  /// and let the backend seed its shifts. The admin picks the MODEL (whole_day /
  /// multi_shift); EduAir derives the shifts — the in-app twin of registration.
  /// Backend guards it to schools with no shifts; the caller invalidates the
  /// shifts provider afterward to pick up the seeded rows.
  Future<void> setupOperatingModel(String operatingModel) async {
    await _dio.post('/api/schools/me/operating-model',
        data: {'operating_model': operatingModel});
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

  /// POST /api/bell-periods — add one bell to a shift. The backend re-validates
  /// everything (times, kind, end > start, that shiftId is ours), so a bad call
  /// 400s rather than writing junk. Returns the saved row (with its new id).
  Future<BellPeriod> createPeriod({
    required int shiftId,
    required int position,
    required String label,
    required String startTime, // 'HH:mm'
    required String endTime,   // 'HH:mm'
    BellSlotType kind = BellSlotType.teaching,
  }) async {
    final res = await _dio.post('/api/bell-periods', data: {
      'shift_id': shiftId,
      'position': position,
      'label': label,
      'start_time': startTime,
      'end_time': endTime,
      'kind': kind.wire, // wire value joins straight to bell_periods.kind
    });
    return BellPeriod.fromMap(res.data['data'] as Map<String, dynamic>);
  }

  /// PUT /api/bell-periods/:id — edit a bell. Fields are nullable to mirror the
  /// backend's COALESCE: send only what changed, leave the rest untouched.
  /// Returns the updated row.
  Future<BellPeriod> updatePeriod(
    int id, {
    int? position,
    String? label,
    String? startTime,
    String? endTime,
    BellSlotType? kind,
  }) async {
    final res = await _dio.put('/api/bell-periods/$id', data: {
      if (position != null) 'position': position,
      if (label != null) 'label': label,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (kind != null) 'kind': kind.wire,
    });
    return BellPeriod.fromMap(res.data['data'] as Map<String, dynamic>);
  }

  /// DELETE /api/bell-periods/:id — soft delete (backend flips status to
  /// 'inactive'; the row stays for history). Throws if it isn't ours (404).
  Future<void> deletePeriod(int id) async {
    await _dio.delete('/api/bell-periods/$id');
  }
}
