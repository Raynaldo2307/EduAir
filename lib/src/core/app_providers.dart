import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as dev;

import 'package:edu_air/src/models/app_user.dart';

// Auth services
import 'package:edu_air/src/features/auth/services/auth_services.dart';

// User service
import 'package:edu_air/src/services/user_services.dart';

// Node API services
import 'package:edu_air/src/services/api_client.dart';
import 'package:edu_air/src/services/token_storage_service.dart';
import 'package:edu_air/src/features/auth/data/auth_api_repository.dart';
import 'package:edu_air/src/features/attendance/data/attendance_api_repository.dart';
import 'package:edu_air/src/features/admin/students/data/students_api_repository.dart';
import 'package:edu_air/src/features/admin/staff/data/staff_api_repository.dart';

// 🔹 Attendance: repo + service
import 'package:edu_air/src/features/attendance/data/attendance_repository.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_service.dart';

// 🔹 NEW: attendance config (holidays)
import 'package:edu_air/src/features/attendance/domain/attendance_config.dart';

// Schoool + Geofencing

import 'package:edu_air/src/features/attendance/domain/attendance_geo_service.dart';
import 'package:edu_air/src/models/school/domain/school.dart';

// Device ID
import 'package:edu_air/src/services/device_id_service.dart';

// 🔹 Attendance: UI-level providers (includes schoolHolidayDateKeysProvider)
//import 'package:edu_air/src/features/attendance/presentation/student/attendance_providers.dart';

/// Device identifier for attendance anti-fraud.
/// Resolves once and caches. Returns `null` on unsupported platforms or errors.
final deviceIdProvider = FutureProvider<String?>((ref) async {
  return DeviceIdService.instance.getDeviceId();
});

/// Controls light / dark mode app-wide.
/// Toggle by writing: ref.read(themeModeProvider.notifier).state = ThemeMode.dark
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

/// Global provider holding the currently authenticated [AppUser].
final userProvider = StateProvider<AppUser?>((ref) => null);

/// Exposes a singleton [AuthService] instance through Riverpod.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Helper provider to access [UserService] wherever needed.
final userServiceProvider = Provider<UserService>((ref) => UserService());

/// Stream provider for real-time user profile updates.
final userProfileStreamProvider = StreamProvider<AppUser?>((ref) {
  final baseUser = ref.watch(userProvider);
  final userService = ref.watch(userServiceProvider);

  if (baseUser == null) {
    return const Stream.empty();
  }

  return userService.watchUser(baseUser.uid);
});

/// Determines the initial route to navigate to after splash.
/// Auth is now Node JWT-based. Firebase is only used for Google Sign In.
final startupRouteProvider = FutureProvider<String>((ref) async {
  final tokenStorage = ref.read(tokenStorageProvider);
  final authRepo = ref.read(authApiRepositoryProvider);
  final userNotifier = ref.read(userProvider.notifier);

  const targetRoute = '/onboarding';

  // Step 1: Check if a Node JWT token is stored on device.
  final token = await tokenStorage.read();
  if (token == null) {
    dev.log('No JWT found — sending to onboarding.', name: 'StartupProvider');
    return targetRoute;
  }

  // Step 2: Validate token by calling /api/auth/me.
  try {
    final userData = await authRepo.getMe();

    final profile = AppUser(
      uid:               userData['id'].toString(),
      firstName:         userData['firstName']        ?? '',
      lastName:          userData['lastName']         ?? '',
      email:             userData['email']            ?? '',
      phone:             '',
      role:              userData['role']             ?? '',
      schoolId:          userData['schoolId']?.toString(),
      defaultShiftType:  userData['defaultShiftType']  as String?,
      isShiftSchool:     userData['isShiftSchool']   as bool? ?? false,
      homeroomClassId:   userData['homeroomClassId']   as String?,
      homeroomClassName: userData['homeroomClassName'] as String?,
    );

    userNotifier.state = profile;
    dev.log('Session restored for ${profile.email}', name: 'StartupProvider');

    // Step 3: Route based on role.
    final role = profile.role;
    final schoolId = profile.schoolId;

    if (role.isEmpty) return '/selectRole';
    if (schoolId == null || schoolId.isEmpty) return '/selectSchool';
    if (role == 'student') return '/studentHome';
    if (role == 'teacher' || role == 'admin' || role == 'principal') {
      return '/teacherHome';
    }
    return targetRoute;
  } catch (e) {
    // Token expired or invalid — clear it and send to onboarding.
    dev.log('JWT invalid: $e — clearing token.', name: 'StartupProvider');
    await tokenStorage.delete();
    return targetRoute;
  }
});

/// 🔹 Attendance repository – wraps Firestore source behind a clean API.
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

/// 🔹 Attendance service – business logic used by UI (student/admin screens).
///
/// Injects:
/// - [AttendanceRepository] for data access
/// - [UserService] for fetching student shift information
/// - [schoolHolidayDateKeysProvider] as the single source of truth for holidays
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  final repo = ref.read(attendanceRepositoryProvider);
  final userService = ref.read(userServiceProvider);
  final holidayKeys = ref.read(schoolHolidayDateKeysProvider);

  return AttendanceService(
    repo: repo,
    userService: userService,
    schoolHolidayDateKeys: holidayKeys,
  );
});

/// 🔹 Geo service – wraps Geolocator and geofence logic.
final attendanceGeoServiceProvider = Provider<AttendanceGeoService>((ref) {
  return const AttendanceGeoService(allowMockLocations: false);
});

// ─── Node API Providers ──────────────────────────────────────────────────────

/// Singleton token storage — persists JWT securely on device.
final tokenStorageProvider = Provider<TokenStorageService>(
  (ref) => const TokenStorageService(),
);

/// Singleton Dio client — injects JWT on every request automatically.
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.read(tokenStorageProvider);
  return ApiClient(tokenStorage);
});

/// Auth API — login, register, logout via Node backend.
final authApiRepositoryProvider = Provider<AuthApiRepository>((ref) {
  return AuthApiRepository(
    client: ref.read(apiClientProvider),
    tokenStorage: ref.read(tokenStorageProvider),
  );
});

/// Attendance API — clock-in/out, history, admin corrections via Node backend.
final attendanceApiRepositoryProvider = Provider<AttendanceApiRepository>((ref) {
  return AttendanceApiRepository(client: ref.read(apiClientProvider));
});

/// Students API — full CRUD for admin student management via Node backend.
final studentsApiRepositoryProvider = Provider<StudentsApiRepository>((ref) {
  return StudentsApiRepository(client: ref.read(apiClientProvider));
});

/// Staff API — full CRUD for admin staff management via Node backend.
final staffApiRepositoryProvider = Provider<StaffApiRepository>((ref) {
  return StaffApiRepository(client: ref.read(apiClientProvider));
});

// ─────────────────────────────────────────────────────────────────────────────

/// The currently active school for this build / environment.
/// Later this can come from Firestore / admin config.
final currentSchoolProvider = Provider<School>((ref) {
  return const School(
    id: 'stony_hill_heart',
    name: 'Stony Hill HEART Academy',
    lat: 18.0827,
    lng: -76.7905,
    radiusMeters: 150.0,
    timezone: 'America/Jamaica',
  );
});
