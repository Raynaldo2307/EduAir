import 'package:dio/dio.dart';
import 'package:edu_air/src/services/api_client.dart';

/// Calls the Node.js students endpoints.
///
/// School scoping is enforced by the server via JWT — admin can only
/// read/write students that belong to their own school.
class StudentsApiRepository {
  final Dio _dio;

  StudentsApiRepository({required ApiClient client}) : _dio = client.dio;

  /// GET /api/students
  /// Returns all students for the school (JWT-scoped).
  Future<List<Map<String, dynamic>>> getAll() async {
    final response = await _dio.get('/api/students');
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  /// GET /api/students?class_id=X
  /// Returns only students in the given class.
  Future<List<Map<String, dynamic>>> getByClass(int classId) async {
    final response = await _dio.get(
      '/api/students',
      queryParameters: {'class_id': classId},
    );
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  /// GET /api/students/:id
  /// Returns a single student. 404 if not in your school.
  Future<Map<String, dynamic>> getById(int id) async {
    final response = await _dio.get('/api/students/$id');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// POST /api/students
  /// Enrols a student — creates user account + student row in one transaction.
  /// Required fields: email, password, first_name, last_name, sex,
  ///                  date_of_birth, current_shift_type
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/students', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// PUT /api/students/:id
  /// Updates student profile fields (shift, phone, sex, etc.).
  Future<Map<String, dynamic>> update(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put('/api/students/$id', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// DELETE /api/students/:id
  /// Soft delete — sets status = 'inactive'. Row is preserved.
  Future<void> delete(int id) async {
    await _dio.delete('/api/students/$id');
  }
}
