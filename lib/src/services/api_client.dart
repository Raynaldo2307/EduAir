import 'package:dio/dio.dart';
import 'package:edu_air/src/services/token_storage_service.dart';

/// Base Dio HTTP client for the EduAir Node.js API.
///
/// - Automatically attaches the JWT token to every request.
/// - Base URL is platform-aware (emulator vs simulator vs device).
/// - All feature repositories receive this client via Riverpod.
/// 
/// /Key thing to say: "The interceptor runs automatically on every request. Repositories don't need       to think    about tokens
 // — the interceptor handles it. That's separation of concerns."

class ApiClient {
  final Dio _dio;

  ApiClient(TokenStorageService tokenStorage)
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.read();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token is invalid or expired — clear it so the next app
            // startup sends the user to onboarding instead of crashing.
            // The UI layer is responsible for navigation (ApiClient has
            // no BuildContext). See debugging playbook BUG-020.
            await tokenStorage.delete();
          }
          handler.next(error);
        },
      ),
    );
  }

  
  Dio get dio => _dio;

  /// Android emulator → 10.0.2.2 maps to host machine localhost.
  /// iOS simulator    → localhost works directly.
  /// Physical device  → must use Mac's LAN IP (localhost won't work across devices).
  ///
  /// DEV: update _devIp if your Mac's IP changes (run: ipconfig getifaddr en0)
  static const _devIp = '192.168.40.171';
  static const _port = '3000';

  static String get _baseUrl {
    return 'http://$_devIp:$_port';
  }
}
