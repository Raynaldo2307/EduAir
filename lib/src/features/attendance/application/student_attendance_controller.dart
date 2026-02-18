// lib/src/features/attendance/application/student_attendance_controller.dart

import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_service.dart';
import 'package:edu_air/src/features/attendance/application/attendance_error_mapper.dart';

/// State for today's attendance record.
///
/// Wraps the [AttendanceDay] in [AsyncValue] for proper loading/error handling.
/// Also includes [lastErrorMessage] for displaying errors in UI.
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
  bool get hasClockedIn => todayRecord?.clockInAt != null;
  bool get hasClockedOut => todayRecord?.clockOutAt != null;
}

/// Controller for student attendance operations (clock in/out, load today).
///
/// This controller:
/// - Exposes today's attendance for the logged-in student
/// - Handles clock in (with late reason validation)
/// - Handles clock out
/// - Maps domain exceptions to user-friendly messages
///
/// Usage in UI:
/// ```dart
/// final state = ref.watch(studentAttendanceControllerProvider);
/// final controller = ref.read(studentAttendanceControllerProvider.notifier);
///
/// // Clock in with late reason
/// await controller.clockIn(location: loc, lateReasonCode: 'transportation');
/// ```
class StudentAttendanceController extends StateNotifier<StudentAttendanceState> {
  final AttendanceService _service;
  final Ref _ref;

  StudentAttendanceController(this._ref, this._service)
      : super(const StudentAttendanceState(today: AsyncValue.loading())) {
    // Load today's record on init
    refreshToday();
  }

  /// Reload today's attendance record.
  ///
  /// Call this after clock-in/out or when returning to the attendance screen.
  Future<void> refreshToday() async {
    final user = _ref.read(userProvider);
    if (user == null || user.schoolId == null) {
      state = const StudentAttendanceState(
        today: AsyncValue.data(null),
        lastErrorMessage: null,
      );
      return;
    }

    state = state.copyWith(today: const AsyncValue.loading(), clearError: true);

    try {
      final day = await _service.getToday(
        schoolId: user.schoolId!,
        studentUid: user.uid,
        // shiftType is derived from user profile in the service
      );

      state = state.copyWith(today: AsyncValue.data(day));
    } catch (e, st) {
      dev.log(
        'StudentAttendanceController.refreshToday failed: $e',
        name: 'StudentAttendanceController',
        error: e,
        stackTrace: st,
      );

      final message = mapAttendanceErrorToMessage(e);
      state = state.copyWith(
        today: AsyncValue.error(e, st),
        lastErrorMessage: message,
      );
    }
  }

  /// Clock in the current student.
  ///
  /// [location] - The student's current GPS location.
  /// [lateReasonCode] - Required if the student is late. Must be a valid MoEYI code.
  ///
  /// Returns the error message if something went wrong, or null on success.
  /// The UI should show a SnackBar with the returned message.
  Future<String?> clockIn({
    required AttendanceLocation location,
    String? lateReasonCode,
  }) async {
    final user = _ref.read(userProvider);
    if (user == null || user.schoolId == null) {
      return 'Please sign in to clock in.';
    }

    state = state.copyWith(today: const AsyncValue.loading(), clearError: true);

    try {
      final deviceId = _ref.read(deviceIdProvider).value;

      final day = await _service.clockIn(
        schoolId: user.schoolId!,
        studentUid: user.uid,
        location: location,
        classId: user.classId,
        className: user.className,
        gradeLevel: user.gradeLevelNumber,
        lateReason: lateReasonCode,
        deviceId: deviceId,
      );

      state = state.copyWith(today: AsyncValue.data(day));

      dev.log(
        'Clock-in success | dateKey=${day.dateKey}, status=${day.status.name}',
        name: 'StudentAttendanceController',
      );

      return null; // Success - no error message
    } catch (e, st) {
      dev.log(
        'StudentAttendanceController.clockIn failed: $e',
        name: 'StudentAttendanceController',
        error: e,
        stackTrace: st,
      );

      final message = mapAttendanceErrorToMessage(e);
      state = state.copyWith(
        today: AsyncValue.error(e, st),
        lastErrorMessage: message,
      );

      return message;
    }
  }

  /// Clock out the current student.
  ///
  /// [location] - The student's current GPS location.
  ///
  /// Returns the error message if something went wrong, or null on success.
  Future<String?> clockOut({
    required AttendanceLocation location,
  }) async {
    final user = _ref.read(userProvider);
    if (user == null || user.schoolId == null) {
      return 'Please sign in to clock out.';
    }

    state = state.copyWith(today: const AsyncValue.loading(), clearError: true);

    try {
      final deviceId = _ref.read(deviceIdProvider).value;

      final day = await _service.clockOut(
        schoolId: user.schoolId!,
        studentUid: user.uid,
        location: location,
        classId: user.classId,
        className: user.className,
        gradeLevel: user.gradeLevelNumber,
        deviceId: deviceId,
      );

      state = state.copyWith(today: AsyncValue.data(day));

      dev.log(
        'Clock-out success | dateKey=${day.dateKey}, clockOutAt=${day.clockOutAt}',
        name: 'StudentAttendanceController',
      );

      return null; // Success
    } catch (e, st) {
      dev.log(
        'StudentAttendanceController.clockOut failed: $e',
        name: 'StudentAttendanceController',
        error: e,
        stackTrace: st,
      );

      final message = mapAttendanceErrorToMessage(e);
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
}

/// Provider for the student attendance controller.
///
/// This is the main entry point for UI to interact with attendance.
final studentAttendanceControllerProvider =
    StateNotifierProvider<StudentAttendanceController, StudentAttendanceState>(
  (ref) {
    final service = ref.watch(attendanceServiceProvider);
    return StudentAttendanceController(ref, service);
  },
);
