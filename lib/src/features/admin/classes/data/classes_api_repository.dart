import 'package:dio/dio.dart';
import 'package:edu_air/src/services/api_client.dart';

class ClassesApiRepository {
  final Dio _dio;

  ClassesApiRepository({required ApiClient client}) : _dio = client.dio;

  /// GET /api/classes — lightweight list for dropdowns
  Future<List<Map<String, dynamic>>> getAll() async {
    final response = await _dio.get('/api/classes');
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  /// GET /api/classes/details — full detail for Classes screen
  Future<List<Map<String, dynamic>>> getAllWithDetails() async {
    final response = await _dio.get('/api/classes/details');
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  /// POST /api/classes — create a new class
  Future<int> createClass({
    required String name,
    required String gradeLevel,
    required int capacity,
  }) async {
    final response = await _dio.post('/api/classes', data: {
      'name':        name,
      'grade_level': gradeLevel,
      'capacity':    capacity,
    });
    return response.data['id'] as int;
  }

  /// PUT /api/classes/:id — update an existing class
  Future<void> updateClass({
    required int id,
    required String name,
    required String gradeLevel,
    required int capacity,
  }) async {
    await _dio.put('/api/classes/$id', data: {
      'name':        name,
      'grade_level': gradeLevel,
      'capacity':    capacity,
    });
  }
}
