import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as dev;

import 'package:edu_air/src/models/app_user.dart';


// Node API services
import 'package:edu_air/src/services/api_client.dart';
import 'package:edu_air/src/services/token_storage_service.dart';
import 'package:edu_air/src/features/auth/data/auth_api_repository.dart';
import 'package:edu_air/src/features/attendance/data/attendance_api_repository.dart';
import 'package:edu_air/src/features/admin/students/data/students_api_repository.dart';
import 'package:edu_air/src/features/admin/staff/data/staff_api_repository.dart';
import 'package:edu_air/src/features/admin/classes/data/classes_api_repository.dart';
import 'package:edu_air/src/features/timetable/data/timetable_api_repository.dart';
import 'package:edu_air/src/features/Teacher/lesson_attendance/data/lesson_attendance_api_repository.dart';
import 'package:edu_air/src/features/registration/data/registration_api_repository.dart';
import 'package:edu_air/src/features/timetable/domain/timetable_entry.dart';
import 'package:edu_air/src/features/admin/reports/data/reports_api_repository.dart';
import 'package:edu_air/src/features/upload/data/upload_api_repository.dart';
import 'package:edu_air/src/features/notices/data/notices_api_repository.dart';
import 'package:edu_air/src/features/admin/staff_attendance/data/staff_attendance_api_repository.dart';


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

/// Determines the initial route to navigate to after splash.
/// Auth is Node JWT-based. Validates stored JWT via /api/auth/me on startup.
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

    // One parser for the Node user shape — shared with login (auth_notifier).
    // Two hand-written constructors used to drift (a restored session dropped
    // classId/currentShift → "No class assigned"); fromMap is the single source.
    final profile = AppUser.fromMap(userData['id'].toString(), userData);

    userNotifier.state = profile;
    dev.log('Session restored for ${profile.email}', name: 'StartupProvider');

    // Step 3: Force password change before anything else.
    if (userData['mustChangePassword'] == true) {
      return '/forceChangePassword';
    }

    // Step 4: Route based on role.
    final role = profile.role;
    final schoolId = profile.schoolId;
  

    if (role.isEmpty) return '/selectRole';
    if (schoolId == null || schoolId.isEmpty) return '/noSchool';
    if (role == 'student') return '/studentHome';
    if (role == 'teacher') {
      return '/teacherHome';
    }
    if (role == 'admin' ||  role == 'principal') {
      return '/adminHome';
    }



    if (role == 'parent') return '/parentHome';
    return targetRoute;
  } catch (e) {
    // Token expired or invalid — clear it and send to onboarding.
    dev.log('JWT invalid: $e — clearing token.', name: 'StartupProvider');
    await tokenStorage.delete();
    return targetRoute;
  }
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

/// Reports API — SF4 PDF export and future report types.
final reportsApiRepositoryProvider = Provider<ReportsApiRepository>((ref) {
  return ReportsApiRepository(ref.read(apiClientProvider));
});

final uploadApiRepositoryProvider = Provider<UploadApiRepository>((ref) {
  return UploadApiRepository(ref.read(apiClientProvider));
});

/// Classes API — returns all classes for the school (used in admin dropdowns).
final classesApiRepositoryProvider = Provider<ClassesApiRepository>((ref) {
  return ClassesApiRepository(client: ref.read(apiClientProvider));
});

/// School classes list — loaded once per admin session for class dropdowns.
final schoolClassesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(classesApiRepositoryProvider).getAll();
});

/// Timetable API — per-class weekly periods. Admin manages; student/teacher view.
final timetableApiRepositoryProvider = Provider<TimetableApiRepository>((ref) {
  return TimetableApiRepository(client: ref.read(apiClientProvider));
});

/// One class's weekly timetable. Family keyed by class id; autoDispose so it
/// re-fetches fresh each time a class is opened. Every shell reads this.
final timetableByClassProvider =
    FutureProvider.autoDispose.family<List<TimetableEntry>, int>((ref, classId) {
  return ref.read(timetableApiRepositoryProvider).getByClass(classId);
});

/// Lesson (subject) attendance API — a subject teacher marks one timetable
/// period. Distinct from the daily register. The roster + prefill providers land
/// with the lesson-roll screen (next step); this exposes the client.
final lessonAttendanceApiRepositoryProvider =
    Provider<LessonAttendanceApiRepository>((ref) {
  return LessonAttendanceApiRepository(client: ref.read(apiClientProvider));
});

/// The logged-in teacher's own periods for one weekday, across all the classes
/// they teach. Family keyed by weekday code ('mon'..'sun') — the caller passes
/// the device weekday so the schedule is correct in the school's timezone.
/// autoDispose so it re-fetches each time the home screen mounts.
final teachingTodayProvider =
    FutureProvider.autoDispose.family<List<TimetableEntry>, String>((ref, day) {
  return ref.read(timetableApiRepositoryProvider).getTeachingToday(day);
});

/// The logged-in teacher's whole week, across every class they teach. Powers the
/// teacher timetable screen — scoped to the teacher (by JWT), not a single
/// class, so a subject teacher sees only her own periods. autoDispose.
final teachingWeekProvider =
    FutureProvider.autoDispose<List<TimetableEntry>>((ref) {
  return ref.read(timetableApiRepositoryProvider).getTeachingWeek();
});

/// Public school-registration endpoint (no auth). Used by the onboarding wizard.
final registrationApiRepositoryProvider = Provider<RegistrationApiRepository>((ref) {
  return RegistrationApiRepository(client: ref.read(apiClientProvider));
});

final noticesApiRepositoryProvider = Provider<NoticesApiRepository>((ref) {
  return NoticesApiRepository(ref.read(apiClientProvider));
});

final staffAttendanceApiRepositoryProvider = Provider<StaffAttendanceApiRepository>((ref) {
  return StaffAttendanceApiRepository(ref.read(apiClientProvider));
});

/// Staff attendance list keyed by date string 'YYYY-MM-DD'.
final staffAttendanceProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, date) {
  return ref.read(staffAttendanceApiRepositoryProvider).getForDate(date);
});

/// Active notices for this school — auto-disposes when admin leaves the dashboard.
final noticesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(noticesApiRepositoryProvider).getAll();
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
