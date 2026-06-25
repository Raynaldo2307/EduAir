import 'package:dio/dio.dart';

import 'package:edu_air/src/services/api_client.dart';
import 'package:edu_air/src/features/timetable/domain/timetable_entry.dart';

/// Talks to /api/timetable. school_id is enforced server-side from the JWT —
/// the client never sends it.
class TimetableApiRepository {
  final Dio _dio;

  TimetableApiRepository({required ApiClient client}) : _dio = client.dio;

  /// GET /api/timetable?class_id=X — one class's weekly periods.
  Future<List<TimetableEntry>> getByClass(int classId) async {
    final response = await _dio.get(
      '/api/timetable',
      queryParameters: {'class_id': classId},
    );
    final rows = List<Map<String, dynamic>>.from(response.data['data'] as List);
    return rows.map(TimetableEntry.fromMap).toList();
  }

  /// GET /api/timetable/teaching-today?day=mon — the logged-in teacher's own
  /// periods for one weekday, across every class they teach. Teacher resolved
  /// server-side from the JWT (never sent by the client). [day] is the device
  /// weekday ('mon'..'sun') so the result stays correct in the school's timezone.
  Future<List<TimetableEntry>> getTeachingToday(String day) async {
    final response = await _dio.get(
      '/api/timetable/teaching-today',
      queryParameters: {'day': day},
    );
    final rows = List<Map<String, dynamic>>.from(response.data['data'] as List);
    return rows.map(TimetableEntry.fromMap).toList();
  }

  /// GET /api/timetable/teaching-week — the logged-in teacher's own periods for
  /// the whole week, across every class they teach. Teacher resolved server-side
  /// from the JWT. Same row shape as teaching-today (carries class_name).
  Future<List<TimetableEntry>> getTeachingWeek() async {
    final response = await _dio.get('/api/timetable/teaching-week');
    final rows = List<Map<String, dynamic>>.from(response.data['data'] as List);
    return rows.map(TimetableEntry.fromMap).toList();
  }

  /// POST /api/timetable — create a period. Returns the new id.
  Future<int> create({
    required int classId,
    required String subject,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    int? teacherId,
    String shiftType = 'whole_day',
    String? room,
  }) async {
    final response = await _dio.post('/api/timetable', data: {
      'class_id':    classId,
      'subject':     subject,
      'day_of_week': dayOfWeek,
      'start_time':  startTime,
      'end_time':    endTime,
      if (teacherId != null) 'teacher_id': teacherId,
      'shift_type':  shiftType,
      if (room != null && room.isNotEmpty) 'room': room,
    });
    return response.data['id'] as int;
  }

  /// PUT /api/timetable/:id — edit a period.
  Future<void> update({
    required int id,
    required String subject,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    int? teacherId,
    String shiftType = 'whole_day',
    String? room,
  }) async {
    await _dio.put('/api/timetable/$id', data: {
      'subject':     subject,
      'day_of_week': dayOfWeek,
      'start_time':  startTime,
      'end_time':    endTime,
      'teacher_id':  teacherId,
      'shift_type':  shiftType,
      'room':        room,
    });
  }

  /// DELETE /api/timetable/:id — soft delete.
  Future<void> delete(int id) async {
    await _dio.delete('/api/timetable/$id');
  }
}
