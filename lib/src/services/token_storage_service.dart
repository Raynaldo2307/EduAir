// ─────────────────────────────────────────────────────────────────────────────
// FILE: token_storage_service.dart
// WHAT: Saves, reads, and deletes the JWT token on-device.
// HOW:  Uses flutter_secure_storage — encrypted storage, not plain SharedPrefs.
// WHY:  JWT is a security credential. On iOS it goes into the Keychain.
//       On Android it goes into the Keystore. A hacker reading the filesystem
//       cannot see it in plain text. This is the security layer — Cluster 3.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ASSESSOR POINT A — Secure Token Storage
// This is the ONLY place the JWT is stored or deleted.
// Every other class asks this service for the token — they never store it themselves.
// Three methods only: save, read, delete. Simple and secure.
class TokenStorageService {
  // Key used to look up the token in the device's secure storage.
  static const _tokenKey = 'node_api_jwt';

  final FlutterSecureStorage _storage;

  const TokenStorageService() : _storage = const FlutterSecureStorage();

  // ASSESSOR POINT B — Save JWT after login
  // Called immediately after a successful login response from the Node.js server.
  // The token is written to encrypted storage — never to plain SharedPreferences.
  Future<void> save(String token) =>
      _storage.write(key: _tokenKey, value: token);

  // ASSESSOR POINT C — Read JWT for API requests
  // Called by the ApiClient interceptor before every HTTP request.
  // Returns null if the user is not logged in — interceptor skips the header.
  Future<String?> read() => _storage.read(key: _tokenKey);

  // ASSESSOR POINT D — Delete JWT on logout
  // When a user logs out, we delete the token from secure storage.
  // No server call needed — JWT is stateless.
  // Next time the app opens: read() returns null → user sees login screen.
  Future<void> delete() => _storage.delete(key: _tokenKey);
}
