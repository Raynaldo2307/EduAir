import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as dev;

import 'package:edu_air/src/models/app_user.dart';

// Auth services
import 'package:edu_air/src/features/auth/services/auth_services.dart';

// User service
import 'package:edu_air/src/services/user_services.dart';

// 🔹 Attendance: repo + service
import 'package:edu_air/src/features/attendance/data/attendance_repository.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_service.dart';

// 🔹 NEW: attendance config (holidays)
import 'package:edu_air/src/features/attendance/domain/attendance_config.dart';

// Schoool + Geofencing

import 'package:edu_air/src/features/attendance/domain/attendance_geo_service.dart';
import 'package:edu_air/src/models/school/domain/school.dart';

// 🔹 Attendance: UI-level providers (includes schoolHolidayDateKeysProvider)
//import 'package:edu_air/src/features/attendance/presentation/student/attendance_providers.dart';

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
final startupRouteProvider = FutureProvider<String>((ref) async {
  final authService = ref.read(authServiceProvider);
  final userService = ref.read(userServiceProvider);
  final userNotifier = ref.read(userProvider.notifier);

  // Step 1: Default route.
  String targetRoute = '/onboarding';

  // Step 2: Check if Firebase user exists.
  final firebaseUser = await authService.getCurrentFirebaseUser();
  if (firebaseUser == null) {
    dev.log('No Firebase user found.', name: 'StartupProvider');
    return targetRoute;
  }

  // Step 3: Fetch profile from Firestore.
  final profile = await userService.getUser(firebaseUser.uid);
  if (profile == null) {
    dev.log(
      'Firebase user found but no profile in Firestore.',
      name: 'StartupProvider',
    );
    return targetRoute;
    //return '/teacherHome';
  }

  // Step 4: Save profile globally.
  userNotifier.state = profile;
  dev.log('Loaded profile for ${profile.uid}', name: 'StartupProvider');

  // Step 5: Determine the route based on user role.
  final role = profile.role;
  final schoolId = profile.schoolId;

  if (role.isEmpty) {
    targetRoute = '/selectRole';
  } else if (schoolId == null || schoolId.isEmpty) {
    // ✅ Role is set but no school yet → go to Select School
    targetRoute = '/selectSchool';
  } else if (role == 'student') {
    targetRoute = '/studentHome'; // StudentShell
  } else if (role == 'teacher') {
    targetRoute = '/teacherHome'; // TeacherShell
  } else {
    targetRoute = '/onboarding';
  }

  return targetRoute;
});

/// 🔹 Attendance repository – wraps Firestore source behind a clean API.
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

/// 🔹 Attendance service – business logic used by UI (student/admin screens).
///
/// Injects:
/// - [AttendanceRepository] for data access
/// - [schoolHolidayDateKeysProvider] as the single source of truth for holidays
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  final repo = ref.read(attendanceRepositoryProvider);
  final holidayKeys = ref.read(schoolHolidayDateKeysProvider);

  return AttendanceService(repo: repo, schoolHolidayDateKeys: holidayKeys);
});

/// 🔹 Geo service – wraps Geolocator and geofence logic.
final attendanceGeoServiceProvider = Provider<AttendanceGeoService>((ref) {
  return const AttendanceGeoService(allowMockLocations: false);
});

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
