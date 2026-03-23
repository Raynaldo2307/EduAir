import 'package:dio/dio.dart';
import 'package:edu_air/src/services/api_client.dart';

/// Calls GET /api/classes — returns all classes for the admin's school.
/// School scoping is enforced server-side via JWT.
class ClassesApiRepository {
  final Dio _dio;

  ClassesApiRepository({required ApiClient client}) : _dio = client.dio;

  /// GET /api/classes
  /// Returns [{id, name, grade_level}, ...]
  Future<List<Map<String, dynamic>>> getAll() async {
    final response = await _dio.get('/api/classes');
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }
}
