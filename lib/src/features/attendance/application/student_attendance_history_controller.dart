// lib/src/features/attendance/application/student_attendance_history_controller.dart

import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_service.dart';
import 'package:edu_air/src/features/attendance/application/attendance_error_mapper.dart';

/// State for student attendance history.
class StudentAttendanceHistoryState {
  final AsyncValue<List<AttendanceDay>> days;
  final String? lastErrorMessage;

  const StudentAttendanceHistoryState({
    required this.days,
    this.lastErrorMessage,
  });

  StudentAttendanceHistoryState copyWith({
    AsyncValue<List<AttendanceDay>>? days,
    String? lastErrorMessage,
    bool clearError = false,
  }) {
    return StudentAttendanceHistoryState(
      days: days ?? this.days,
      lastErrorMessage: clearError ? null : (lastErrorMessage ?? this.lastErrorMessage),
    );
  }

  /// Convenience getters
  bool get isLoading => days.isLoading;
  bool get hasError => days.hasError || lastErrorMessage != null;
  List<AttendanceDay> get daysList => days.valueOrNull ?? [];
}

/// Controller for student attendance history.
///
/// This controller:
/// - Loads recent attendance days for the logged-in student
/// - Provides summary statistics (present/absent counts)
/// - Maps domain exceptions to user-friendly messages
///
/// Usage:
/// ```dart
/// final state = ref.watch(studentAttendanceHistoryControllerProvider);
/// final controller = ref.read(studentAttendanceHistoryControllerProvider.notifier);
///
/// // Reload history
/// await controller.loadRecent(limit: 14);
/// ```
class StudentAttendanceHistoryController
    extends StateNotifier<StudentAttendanceHistoryState> {
  final AttendanceService _service;
  final Ref _ref;

  StudentAttendanceHistoryController(this._ref, this._service)
      : super(const StudentAttendanceHistoryState(
            days: AsyncValue.loading())) {
    // Load recent days on init
    loadRecent();
  }

  /// Load recent attendance days.
  ///
  /// [limit] - Number of days to load (default: 14).
  /// [shiftType] - Optional shift filter. If null, uses student's currentShift
  ///               from their profile, or defaults to 'whole_day'.
  Future<void> loadRecent({int limit = 14, String? shiftType}) async {
    final user = _ref.read(userProvider);
    if (user == null || user.schoolId == null) {
      state = const StudentAttendanceHistoryState(
        days: AsyncValue.data([]),
        lastErrorMessage: null,
      );
      return;
    }

    state = state.copyWith(days: const AsyncValue.loading(), clearError: true);

    try {
      // If no shiftType provided, let the service derive from user profile
      final effectiveShift = shiftType ?? user.currentShift;

      final days = await _service.getRecentDays(
        schoolId: user.schoolId!,
        studentUid: user.uid,
        limit: limit,
        shiftType: effectiveShift,
      );

      state = state.copyWith(days: AsyncValue.data(days));

      dev.log(
        'Loaded ${days.length} recent days for ${user.uid}',
        name: 'StudentAttendanceHistoryController',
      );
    } catch (e, st) {
      dev.log(
        'StudentAttendanceHistoryController.loadRecent failed: $e',
        name: 'StudentAttendanceHistoryController',
        error: e,
        stackTrace: st,
      );

      final message = mapAttendanceErrorToMessage(e);
      state = state.copyWith(
        days: AsyncValue.error(e, st),
        lastErrorMessage: message,
      );
    }
  }

  /// Refresh the history (convenience method).
  Future<void> refresh() => loadRecent();

  /// Clear any stored error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for the student attendance history controller.
final studentAttendanceHistoryControllerProvider = StateNotifierProvider<
    StudentAttendanceHistoryController, StudentAttendanceHistoryState>(
  (ref) {
    final service = ref.watch(attendanceServiceProvider);
    return StudentAttendanceHistoryController(ref, service);
  },
);

/// Summary statistics computed from history.
class AttendanceStats {
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int earlyCount;
  final int totalDays;

  const AttendanceStats({
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.earlyCount,
    required this.totalDays,
  });

  factory AttendanceStats.fromDays(List<AttendanceDay> days) {
    int present = 0;
    int absent = 0;
    int late = 0;
    int early = 0;

    for (final day in days) {
      switch (day.status) {
        case AttendanceStatus.early:
          present++;
          early++;
          break;
        case AttendanceStatus.late:
          present++;
          late++;
          break;
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
        case AttendanceStatus.excused:
          absent++;
          break;
      }
    }

    return AttendanceStats(
      presentCount: present,
      absentCount: absent,
      lateCount: late,
      earlyCount: early,
      totalDays: days.length,
    );
  }

  /// Attendance rate as a percentage (0-100).
  double get attendanceRate =>
      totalDays > 0 ? (presentCount / totalDays) * 100 : 0;

  /// Punctuality rate as a percentage of on-time arrivals.
  double get punctualityRate =>
      presentCount > 0 ? (earlyCount / presentCount) * 100 : 0;
}

/// Provider that computes attendance stats from history.
final studentAttendanceStatsProvider = Provider<AttendanceStats>((ref) {
  final historyState = ref.watch(studentAttendanceHistoryControllerProvider);
  return AttendanceStats.fromDays(historyState.daysList);
});
