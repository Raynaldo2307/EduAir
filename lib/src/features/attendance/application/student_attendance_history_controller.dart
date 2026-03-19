// lib/src/features/attendance/application/student_attendance_history_controller.dart

import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/attendance/data/attendance_api_repository.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';

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
/// Uses the Node API via [AttendanceApiRepository] — no Firestore access.
class StudentAttendanceHistoryController
    extends StateNotifier<StudentAttendanceHistoryState> {
  final AttendanceApiRepository _repo;
  final Ref _ref;

  StudentAttendanceHistoryController(this._ref, this._repo)
      : super(const StudentAttendanceHistoryState(
            days: AsyncValue.loading())) {
    loadRecent();
  }

  /// Load recent attendance days from the Node API.
  ///
  /// [limit] - Number of days to load (default: 14).
  /// [shiftType] - Optional shift filter.
  Future<void> loadRecent({int limit = 14, String? shiftType}) async {
    final user = _ref.read(userProvider);
    if (user == null) {
      state = const StudentAttendanceHistoryState(
        days: AsyncValue.data([]),
        lastErrorMessage: null,
      );
      return;
    }

    state = state.copyWith(days: const AsyncValue.loading(), clearError: true);

    try {
      final effectiveShift = shiftType ?? user.currentShift;
      final records = await _repo.getMyHistory(
        limit: limit,
        shiftType: effectiveShift,
      );

      final days = records
          .map((r) => AttendanceDay.fromApiMap(r, studentUid: user.uid))
          .toList();

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

      final message = _mapError(e);
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

  String _mapError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == 401) return 'Session expired. Please sign in again.';
      if (status == 403) return 'Permission denied.';
      return 'Network error. Please check your connection and try again.';
    }
    return 'Something went wrong while loading attendance. Please try again.';
  }
}

/// Provider for the student attendance history controller.
///
/// Uses the Node API — no Firestore access required.
final studentAttendanceHistoryControllerProvider = StateNotifierProvider<
    StudentAttendanceHistoryController, StudentAttendanceHistoryState>(
  (ref) {
    final repo = ref.watch(attendanceApiRepositoryProvider);
    return StudentAttendanceHistoryController(ref, repo);
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
