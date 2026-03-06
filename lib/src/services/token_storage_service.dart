import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the Node API JWT token securely on-device.
/// Use this instead of SharedPreferences — tokens are sensitive.
class TokenStorageService {
  static const _tokenKey = 'node_api_jwt';

  final FlutterSecureStorage _storage;

  const TokenStorageService()
      : _storage = const FlutterSecureStorage();

  /// Save the JWT after a successful login.
  Future<void> save(String token) =>
      _storage.write(key: _tokenKey, value: token);

  /// Read the stored JWT. Returns null if not logged in.
  Future<String?> read() => _storage.read(key: _tokenKey);

  /// Delete the JWT on logout.
  Future<void> delete() => _storage.delete(key: _tokenKey);
}
