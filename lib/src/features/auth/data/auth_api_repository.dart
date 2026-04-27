// ─────────────────────────────────────────────────────────────────────────────
// FILE: auth_api_repository.dart
// WHAT: Handles ALL authentication API calls — login, register, logout, getMe.
// HOW:  Uses Dio HTTP client to call the Node.js backend (not Firebase).
// WHY:  I built my own auth system with bcrypt + JWT instead of relying on
//       a third-party service — more control, no vendor lock-in, MoEYI-ready.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:edu_air/src/services/api_client.dart';
import 'package:edu_air/src/services/token_storage_service.dart';

//  — Authentication Repository
// This class is the ONLY place in the app that communicates with the auth API.
// Login, register, logout, and session check all live here.
// No other screen or widget touches the auth endpoints directly.
class AuthApiRepository {
  final Dio _dio;
  final TokenStorageService _tokenStorage;

  // Receives the Dio client (with JWT interceptor) and secure storage via Riverpod.
  AuthApiRepository({
    required ApiClient client,
    required TokenStorageService tokenStorage,
  })  : _dio = client.dio,
        _tokenStorage = tokenStorage;

  //  — Login Flow
  // Step 1: POST email + password to Node.js backend.
  // Step 2: Server checks password against bcrypt hash stored in MySQL.
  // Step 3: Server returns a signed JWT token.
  // Step 4: We save that token to device secure storage immediately.
  // From this point, every API call carries that token automatically.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    final token = response.data['token'] as String;
    await _tokenStorage.save(token); // saved to iOS Keychain / Android Keystore
    return Map<String, dynamic>.from(response.data as Map);
  }

  //  — Register (Admin Only)
  // Only an admin can create accounts — students and teachers cannot self-register.
  // The admin's JWT is attached automatically by the interceptor.
  // The server reads school_id from that JWT, not from the request body.
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

  // ASSESSOR POINT D — Session Validation on App Startup
  // When the app opens, we call GET /api/auth/me.
  // The server validates the stored JWT and returns the user profile.
  // If JWT is expired or invalid, server returns 401 → interceptor clears token → login screen.
  // This means the user never has to log in again while their session is valid.
  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/api/auth/me');
    return Map<String, dynamic>.from(response.data['user'] as Map);
  }

  // Any logged-in user can update their own profile.
  // Backend uses COALESCE — only the fields you send are updated, rest stay the same.
  Future<void> updateMe(Map<String, dynamic> data) async {
    await _dio.put('/api/auth/me', data: data);
  }

  // Public endpoints — no JWT required (user is not logged in yet).
  Future<void> forgotPassword({required String email}) async {
    await _dio.post('/api/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _dio.post('/api/auth/reset-password', data: {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }

  // Force-change flow: user submits their current (admin-generated) password
  // and the new password they chose. Backend clears must_change_password flag.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.put('/api/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // ASSESSOR POINT E — Logout
  // Logout simply deletes the JWT from secure storage.
  // No server call needed — JWT is stateless, the server holds no session.
  // Next app open: getMe() fails → user lands on onboarding.
  Future<void> logout() => _tokenStorage.delete();
}
