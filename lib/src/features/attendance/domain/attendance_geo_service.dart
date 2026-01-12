// lib/src/features/attendance/domain/attendance_geo_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:edu_air/src/models/school/domain/school.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';

/// AttendanceGeoService
/// --------------------
/// Small wrapper around Geolocator so the rest of the app can ask:
///   - "Is this user currently inside the school's geofence?"
///   - "What lat/lng should we store on the attendance record?"
class AttendanceGeoService {
  const AttendanceGeoService({this.allowMockLocations = false});

  /// When true, we won't block mocked GPS (for emulator / QA).
  final bool allowMockLocations;

  /// Internal helper: ensure location services + permissions are OK,
  /// then return the current position.
  Future<Position> _getCurrentPosition() async {
    // 1) Check if location services are enabled on the device.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    // 2) Check permission status.
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Ask once.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const PermissionDeniedException('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException(
        'Location permissions are permanently denied.',
      );
    }

    // 3) Get the current position (new geolocator API).
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    // 4) Optional anti–fake GPS check.
    if (position.isMocked && !allowMockLocations) {
      // 👇 Throw the *specific* fake-GPS error so UI can strike-count it
      throw const MockLocationsException();
    }

    return position;
  }

  /// Checks if the current user is inside the given [school]'s geofence.
  Future<bool> isUserOnCampus(School school) async {
    final position = await _getCurrentPosition();

    final distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      school.lat,
      school.lng,
    );

    return distanceInMeters <= school.radiusMeters;
  }

  /// Returns current device location as [AttendanceLocation] for saving.
  Future<AttendanceLocation> currentAttendanceLocation() async {
    final position = await _getCurrentPosition();
    return AttendanceLocation(lat: position.latitude, lng: position.longitude);
  }
}

/// Simple exception types so UI can distinguish error states.
class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();

  @override
  String toString() => 'Location services are disabled.';
}

class PermissionDeniedException implements Exception {
  final String message;
  const PermissionDeniedException(this.message);

  @override
  String toString() => message;
}

/// 🔥 Specific exception just for fake/mock GPS
class MockLocationsException implements Exception {
  const MockLocationsException();

  @override
  String toString() => 'Mock (fake) location detected.';
}
