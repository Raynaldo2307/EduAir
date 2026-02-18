import 'dart:io';
import 'dart:developer' as dev;

import 'package:device_info_plus/device_info_plus.dart';

/// Retrieves and caches the device identifier for attendance anti-fraud.
///
/// Platform support:
/// - Android: `androidInfo.id` (device hardware ID)
/// - iOS: `iosInfo.identifierForVendor` (app-scoped UUID)
/// - Others: returns `null`
///
/// The device ID is cached in memory after first retrieval.
/// Never throws -- all errors are caught and logged.
class DeviceIdService {
  DeviceIdService._();
  static final DeviceIdService instance = DeviceIdService._();

  final DeviceInfoPlugin _plugin = DeviceInfoPlugin();
  String? _cachedDeviceId;
  bool _hasAttempted = false;

  /// Get the device ID (cached after first call).
  ///
  /// Returns `null` if platform is unsupported or retrieval fails.
  Future<String?> getDeviceId() async {
    if (_hasAttempted) return _cachedDeviceId;

    _hasAttempted = true;

    try {
      if (Platform.isAndroid) {
        final info = await _plugin.androidInfo;
        _cachedDeviceId = info.id;
      } else if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        _cachedDeviceId = info.identifierForVendor;
      }

      dev.log(
        'Device ID retrieved: ${_cachedDeviceId ?? "null"} '
        '(${Platform.operatingSystem})',
        name: 'DeviceIdService',
      );
    } catch (e, st) {
      dev.log(
        'Failed to retrieve device ID: $e',
        name: 'DeviceIdService',
        error: e,
        stackTrace: st,
      );
      _cachedDeviceId = null;
    }

    return _cachedDeviceId;
  }
}
