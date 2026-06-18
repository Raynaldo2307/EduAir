import 'package:dio/dio.dart';

import 'package:edu_air/src/services/api_client.dart';

/// Talks to the PUBLIC school-registration endpoint. No JWT — a principal
/// onboarding a school isn't logged in yet.
///
/// Slice 2b-1 registers the SCHOOL row only. Creating the principal's login
/// account (needs a password + name + email delivery) is a separate slice.
class RegistrationApiRepository {
  final Dio _dio;

  RegistrationApiRepository({required ApiClient client}) : _dio = client.dio;

  /// POST /api/schools — create a new school. Throws DioException on failure
  /// (e.g. 409 if a school with that name/parish already exists).
  Future<void> registerSchool({
    required String name,
    required String parish,
    required String schoolType,      // matches backend `school_type` enum
    required bool isShiftSchool,
    required String defaultShiftType, // 'morning' | 'afternoon' | 'whole_day'
    required int radiusMeters,
    required String adminFirstName,
    required String adminLastName,
    required String adminEmail,
    required String password,
  }) async {
    await _dio.post('/api/schools', data: {
      'name': name,
      'parish': parish,
      'school_type': schoolType,
      'is_shift_school': isShiftSchool,
      'default_shift_type': defaultShiftType,
      'radius_meters': radiusMeters,
      'admin_first_name': adminFirstName,
      'admin_last_name': adminLastName,
      'admin_email': adminEmail,
      'password': password,
    });
  }
}
