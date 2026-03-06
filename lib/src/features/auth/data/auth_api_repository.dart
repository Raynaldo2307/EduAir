import 'package:dio/dio.dart';
import 'package:edu_air/src/services/api_client.dart';
import 'package:edu_air/src/services/token_storage_service.dart';

/// Calls the Node.js auth endpoints.
///
/// Responsibilities:
/// - POST /api/auth/login  → verifies credentials, saves JWT
/// - POST /api/auth/register → admin creates a new user account
/// - logout → deletes the stored JWT
class AuthApiRepository {
  final Dio _dio;
  final TokenStorageService _tokenStorage;

  AuthApiRepository({
    required ApiClient client,
    required TokenStorageService tokenStorage,
  })  : _dio = client.dio,
        _tokenStorage = tokenStorage;

  /// Login with email + password.
  /// Saves the returned JWT automatically.
  /// Returns the full response body (includes token + user object).
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    final token = response.data['token'] as String;
    await _tokenStorage.save(token);
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Register a new user — only callable by admin/principal.
  /// JWT from the current admin session is sent automatically via interceptor.
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    final response = await _dio.post(
      '/api/auth/register',
      data: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// GET /api/auth/me — validates the stored JWT and returns the current user.
  /// Call this on app startup to check if the session is still valid.
  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/api/auth/me');
    return Map<String, dynamic>.from(response.data['user'] as Map);
  }

  /// Clear the stored JWT on logout.
  Future<void> logout() => _tokenStorage.delete();
}
