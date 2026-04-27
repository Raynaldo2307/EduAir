// ─────────────────────────────────────────────────────────────────────────────
// FILE: student_attendance_controller.dart
// WHAT: The brain that controls what happens when a student clocks in or out.
// HOW:  Riverpod StateNotifier — holds the current attendance state and exposes
//       methods the UI calls (clockIn, clockOut, refreshToday).
// WHY:  The UI should never talk directly to the API. The controller sits between
//       the UI and the repository. That is the application layer — clean architecture.
//       UI → Controller → Repository → Node.js API → MySQL
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_error_handler.dart';
import 'package:edu_air/src/features/attendance/data/attendance_api_repository.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';

// ASSESSOR POINT A — State Object
// StudentAttendanceState holds everything the UI needs to know:
// 1. today   — the student's attendance record for today (or null if not clocked in)
// 2. lastErrorMessage — any error to show the user (e.g. "Already clocked in")
// AsyncValue is a Riverpod wrapper that handles loading/data/error states cleanly.
class StudentAttendanceState {
  final AsyncValue<AttendanceDay?> today;
  final String? lastErrorMessage;

  const StudentAttendanceState({
    required this.today,
    this.lastErrorMessage,
  });

  StudentAttendanceState copyWith({
    AsyncValue<AttendanceDay?>? today,
    String? lastErrorMessage,
    bool clearError = false,
  }) {
    return StudentAttendanceState(
      today: today ?? this.today,
      lastErrorMessage: clearError ? null : (lastErrorMessage ?? this.lastErrorMessage),
    );
  }

  /// Convenience getters for UI
  bool get isLoading => today.isLoading;
  bool get hasError => today.hasError || lastErrorMessage != null;
  AttendanceDay? get todayRecord => today.valueOrNull;

  /// True when a teacher manually marked this student present (no self clock-in).
  bool get isTeacherMarked =>
      (todayRecord?.status.isPresentLike ?? false) &&
      todayRecord?.clockInAt == null;

  /// Clocked in by self OR marked present by teacher.
  bool get hasClockedIn => todayRecord?.clockInAt != null || isTeacherMarked;

  /// Clocked out OR teacher-marked (no clock-out expected for manual records).
  bool get hasClockedOut => todayRecord?.clockOutAt != null || isTeacherMarked;
}

// ASSESSOR POINT B — Controller Class
// StudentAttendanceController manages clock-in, clock-out, and today's record.
// It uses Node API via AttendanceApiRepository — no Firebase, no Firestore.
// On creation it immediately calls refreshToday() to load the student's current status.
class StudentAttendanceController extends StateNotifier<StudentAttendanceState> {
  final AttendanceApiRepository _repo;
  final Ref _ref;

  StudentAttendanceController(this._ref, this._repo)
      : super(const StudentAttendanceState(today: AsyncValue.loading())) {
    refreshToday();
  }

  // ASSESSOR POINT C — Load Today's Record
  // Called on app start and after every clock-in/clock-out.
  // Asks the Node API "what is this student's record for today?"
  // Server identifies the student from the JWT — the student ID is never passed manually.
  Future<void> refreshToday() async {
    final user = _ref.read(userProvider);
    if (user == null) {
      state = const StudentAttendanceState(
        today: AsyncValue.data(null),
        lastErrorMessage: null,
      );
      return;
    }

    state = state.copyWith(today: const AsyncValue.loading(), clearError: true);

    try {
      final raw = await _repo.getMyToday();
      final day = raw != null
          ? AttendanceDay.fromApiMap(raw, studentUid: user.uid)
          : null;
      state = state.copyWith(today: AsyncValue.data(day));
    } catch (e, st) {
      final message = _mapError(e, st);
      state = state.copyWith(
        today: AsyncValue.error(e, st),
        lastErrorMessage: message,
      );
    }
  }

  // ASSESSOR POINT D — Clock In
  // UI calls this when the student taps the Clock In button.
  // Step 1: Check the user is logged in.
  // Step 2: Determine shift type from the user's profile.
  // Step 3: Call the repository → Node API POST /api/attendance/clock-in.
  // Step 4: Server calculates early vs late using Jamaica server time.
  // Step 5: Reload today's record to update the UI.
  // Returns null on success, or an error message string on failure.
  Future<String?> clockIn({
    required AttendanceLocation location,
    String? lateReasonCode,
  }) async {
    final user = _ref.read(userProvider);
    if (user == null) return 'Please sign in to clock in.';

    state = state.copyWith(today: const AsyncValue.loading(), clearError: true);

    try {
      final shiftType = AttendanceDay.normalizeShiftType(user.currentShift);
      final deviceId = _ref.read(deviceIdProvider).value;

      await _repo.clockIn(
        shiftType: shiftType,
        lat: location.lat,
        lng: location.lng,
        lateReasonCode: lateReasonCode,
        deviceId: deviceId,
      );

      dev.log('Clock-in success', name: 'StudentAttendanceController');

      // Reload to get the full record with timestamps from the server.
      await refreshToday();
      return null;
    } catch (e, st) {
      final message = _mapError(e, st);
      state = state.copyWith(
        today: AsyncValue.error(e, st),
        lastErrorMessage: message,
      );
      return message;
    }
  }

  // ASSESSOR POINT E — Clock Out
  // UI calls this when the student taps the Clock Out button.
  // Step 1: Fetch today's record to get the MySQL row ID.
  // Step 2: Call PUT /api/attendance/:id/clock-out with GPS coordinates.
  // Step 3: Reload today's record to update the UI.
  // If no clock-in record is found, the user sees a clear error message.
  Future<String?> clockOut({
    required AttendanceLocation location,
  }) async {
    final user = _ref.read(userProvider);
    if (user == null) return 'Please sign in to clock out.';

    state = state.copyWith(today: const AsyncValue.loading(), clearError: true);

    try {
      // Fetch today's record to get the MySQL row ID required by the PUT endpoint.
      final todayRaw = await _repo.getMyToday();
      final attendanceId = todayRaw?['id'] as int?;

      if (attendanceId == null) {
        state = state.copyWith(
          today: const AsyncValue.data(null),
          lastErrorMessage: 'No clock-in found for today.',
        );
        return 'No clock-in found for today. Please clock in first.';
      }

      await _repo.clockOut(
        attendanceId: attendanceId,
        lat: location.lat,
        lng: location.lng,
      );

      dev.log('Clock-out success', name: 'StudentAttendanceController');

      await refreshToday();
      return null;
    } catch (e, st) {
      final message = _mapError(e, st);
      state = state.copyWith(
        today: AsyncValue.error(e, st),
        lastErrorMessage: message,
      );
      return message;
    }
  }

  /// Clear any stored error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _mapError(Object e, [StackTrace? st]) =>
      AppErrorHandler.message(e, context: 'Attendance', stackTrace: st);
}

/// Provider for the student attendance controller.
///
/// Uses the Node API — no Firestore access required.
final studentAttendanceControllerProvider =
    StateNotifierProvider<StudentAttendanceController, StudentAttendanceState>(
  (ref) {
    final repo = ref.watch(attendanceApiRepositoryProvider);
    return StudentAttendanceController(ref, repo);
  },
);
