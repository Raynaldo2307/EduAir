// lib/src/features/attendance/application/student_attendance_controller.dart

import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_error_handler.dart';
import 'package:edu_air/src/features/attendance/data/attendance_api_repository.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';

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

  /// True when a teacher manually marked this student present (no self clock-in).
  bool get isTeacherMarked =>
      (todayRecord?.status.isPresentLike ?? false) &&
      todayRecord?.clockInAt == null;

  /// Clocked in by self OR marked present by teacher.
  bool get hasClockedIn => todayRecord?.clockInAt != null || isTeacherMarked;

  /// Clocked out OR teacher-marked (no clock-out expected for manual records).
  bool get hasClockedOut => todayRecord?.clockOutAt != null || isTeacherMarked;
}

/// Controller for student attendance operations (clock in/out, load today).
///
/// Uses the Node API via [AttendanceApiRepository] — no Firestore access.
class StudentAttendanceController extends StateNotifier<StudentAttendanceState> {
  final AttendanceApiRepository _repo;
  final Ref _ref;

  StudentAttendanceController(this._ref, this._repo)
      : super(const StudentAttendanceState(today: AsyncValue.loading())) {
    refreshToday();
  }

  /// Reload today's attendance record from the Node API.
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

  /// Clock in the current student via Node API.
  ///
  /// Returns an error message on failure, or null on success.
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

  /// Clock out the current student via Node API.
  ///
  /// Returns an error message on failure, or null on success.
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
