import 'package:dio/dio.dart';
import 'package:edu_air/src/services/api_client.dart';

class NoticesApiRepository {
  final Dio _dio;

  NoticesApiRepository(ApiClient client) : _dio = client.dio;

  /// GET /api/notices — all active, non-expired notices for this school.
  Future<List<Map<String, dynamic>>> getAll() async {
    final response = await _dio.get('/api/notices');
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  /// POST /api/notices — admin creates a new notice.
  Future<int> create({
    required String title,
    required String body,
    required String category,
    String? expiresAt,
  }) async {
    final response = await _dio.post('/api/notices', data: {
      'title':      title,
      'body':       body,
      'category':   category,
      if (expiresAt != null) 'expires_at': expiresAt,
    });
    return response.data['id'] as int;
  }

  /// DELETE /api/notices/:id
  Future<void> delete(int id) async {
    await _dio.delete('/api/notices/$id');
  }
}
