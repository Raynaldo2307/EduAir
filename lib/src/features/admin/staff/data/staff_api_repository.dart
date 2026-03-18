import 'package:dio/dio.dart';
import 'package:edu_air/src/services/api_client.dart';

/// Calls the Node.js /api/staff endpoints.
///
/// School scoping is enforced by the server via JWT — admin can only
/// read/write staff that belong to their own school.
class StaffApiRepository {
  final Dio _dio;

  StaffApiRepository({required ApiClient client}) : _dio = client.dio;

  /// GET /api/staff
  /// Returns all active staff for the admin's school (JWT-scoped).
  Future<List<Map<String, dynamic>>> getAll() async {
    final response = await _dio.get('/api/staff');
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  /// GET /api/staff/:id
  /// Returns a single staff member. 404 if not in your school.
  Future<Map<String, dynamic>> getById(int id) async {
    final response = await _dio.get('/api/staff/$id');
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  /// POST /api/staff
  /// Creates a teacher — user account + teacher row in one transaction.
  /// Required: email, password, first_name, last_name
  /// Optional: staff_code, department, employment_type, hire_date,
  ///           current_shift_type, homeroom_class_id
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/staff', data: data);
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  /// PUT /api/staff/:id
  /// Updates staff profile fields (name, department, shift, etc.).
  Future<Map<String, dynamic>> update(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put('/api/staff/$id', data: data);
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  /// DELETE /api/staff/:id
  /// Soft delete — sets status = 'inactive'. Row is preserved.
  Future<void> delete(int id) async {
    await _dio.delete('/api/staff/$id');
  }
}
