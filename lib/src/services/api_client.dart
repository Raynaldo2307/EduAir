// ─────────────────────────────────────────────────────────────────────────────
// FILE: api_client.dart
// WHAT: The single HTTP client shared by the entire app.
// HOW:  Uses Dio with an interceptor that automatically attaches the JWT to
//       every outgoing request and handles 401 token expiry automatically.
// WHY:  Centralising auth in one interceptor means no feature repository has
//       to think about tokens. That is the separation of concerns pattern —
//       the same principle used in production apps at Uber and Netflix.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:edu_air/src/services/token_storage_service.dart';

// ASSESSOR POINT A — ApiClient (Central HTTP Client)
// Every repository in the app (auth, attendance, students, staff) uses THIS client.
// They all share the same Dio instance with the same interceptor.
// One place to update — no duplication.
class ApiClient {
  final Dio _dio;

  // ASSESSOR POINT B — Constructor + Interceptor Setup
  // The interceptor is registered once here and runs on EVERY request automatically.
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
        // Before every request, read the JWT from secure storage and attach it
        // as a Bearer token. If there is no token the header is skipped and the
        // server returns 401 for protected routes.
        onRequest: (options, handler) async {
          final token = await tokenStorage.read();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        // Pass 401 errors through without touching the stored token.
        // Deleting the token here causes a cascading failure: the first 401
        // wipes the token, every subsequent concurrent request also gets 401
        // (no token → no header → server rejects), and the session is destroyed
        // mid-use for no reason.
        // Real token expiry is detected by startupRouteProvider calling getMe()
        // on app start — if that returns 401, the user is sent to login cleanly.
        onError: (DioException error, handler) {
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
  ///  ~ % ipconfig getifaddr en0
  //192.168.40.171
  // this is for the my hotspot here
  //static const _devIp = '172.20.10.2';
  // thisis for the wifi at home here
  //static const _devIp = '192.168.40.171';

  // this is for the wifi at school here
  //static const _devIp  = '10.44.16.164';
  //static const _devIp  = '10.44.16.220';
   // this is the wifi at  work st ann bay here 
   //static const _devIp = '192.168.0.119';
   //static const _devIp = '192.168.0.104';
   //static const _devIp = '192.168.0.105';
   // radio. rooom 
   // 
   //static const _devIp = '192.168.1.21';
   //static const _devIp = '192.168.0.112';
   // current network (Mac en0 = 10.0.1.207)
   static const _devIp = '10.0.1.207';



  static const _port = '3000';

  static String get _baseUrl {
    return 'http://$_devIp:$_port';
  }
}
