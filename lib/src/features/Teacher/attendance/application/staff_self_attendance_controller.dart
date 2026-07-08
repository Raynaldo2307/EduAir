// ─────────────────────────────────────────────────────────────────────────────
// FILE: staff_self_attendance_controller.dart
// WHAT: The brain for a staff member clocking THEMSELVES in/out.
// HOW:  Riverpod StateNotifier — mirrors StudentAttendanceController.
// WHY:  Same architecture as the student side: UI → Controller → Repository →
//       Node API → MySQL. The server is the only judge of late (the phone's
//       clock has no vote); a late clock-in comes back LATE_REASON_REQUIRED,
//       the UI collects the MoEYI reason, and we resubmit.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/admin/staff_attendance/data/staff_attendance_api_repository.dart';

/// Everything the Teacher tab needs to render the clock block.
/// `today` is the raw record map from the API (null = nothing recorded yet).
class StaffSelfAttendanceState {
  final AsyncValue<Map<String, dynamic>?> today;
  final bool isSubmitting;

  const StaffSelfAttendanceState({
    required this.today,
    this.isSubmitting = false,
  });

  StaffSelfAttendanceState copyWith({
    AsyncValue<Map<String, dynamic>?>? today,
    bool? isSubmitting,
  }) {
    return StaffSelfAttendanceState(
      today: today ?? this.today,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  Map<String, dynamic>? get record => today.valueOrNull;

  /// Clocked in by self OR marked by admin (admin marks carry no clock_in —
  /// a status with no clock_in still means "your day is recorded").
  bool get hasClockedIn => record != null;

  /// True only for a real self clock-in (there's a time to clock out from).
  bool get hasSelfClockIn => record?['clock_in'] != null;

  bool get hasClockedOut =>
      record?['clock_out'] != null ||
      // Admin-marked (no clock_in) → no clock-out expected; day is closed.
      (record != null && record?['clock_in'] == null);

  String? get status => record?['status'] as String?;
  int? get attendanceId => record?['id'] as int?;
}

class StaffSelfAttendanceController
    extends StateNotifier<StaffSelfAttendanceState> {
  final StaffAttendanceApiRepository _repo;

  StaffSelfAttendanceController(this._repo)
      : super(const StaffSelfAttendanceState(today: AsyncValue.loading())) {
    refreshToday();
  }

  /// Load my record for today. Identity comes from the JWT — the server
  /// resolves user → staff row itself.
  Future<void> refreshToday() async {
    state = state.copyWith(today: const AsyncValue.loading());
    try {
      final raw = await _repo.getMyToday();
      state = state.copyWith(today: AsyncValue.data(raw));
    } catch (e, st) {
      state = state.copyWith(today: AsyncValue.error(e, st));
    }
  }

  /// Clock in. Throws [LateReasonRequiredException] straight through to the
  /// UI — the page owns the MoEYI dialog and calls again with the reason.
  Future<void> clockIn({
    required double lat,
    required double lng,
    String? lateReasonCode,
  }) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _repo.clockIn(lat: lat, lng: lng, lateReasonCode: lateReasonCode);
      dev.log('Staff clock-in success', name: 'StaffSelfAttendance');
      await refreshToday();
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  /// Clock out my own record (row id comes from today's record).
  Future<void> clockOut({required double lat, required double lng}) async {
    final id = state.attendanceId;
    if (id == null) {
      throw StateError('No clock-in found for today.');
    }
    state = state.copyWith(isSubmitting: true);
    try {
      await _repo.clockOut(attendanceId: id, lat: lat, lng: lng);
      dev.log('Staff clock-out success', name: 'StaffSelfAttendance');
      await refreshToday();
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}

final staffSelfAttendanceControllerProvider = StateNotifierProvider<
    StaffSelfAttendanceController, StaffSelfAttendanceState>((ref) {
  final repo = ref.watch(staffAttendanceApiRepositoryProvider);
  return StaffSelfAttendanceController(repo);
});

/// My own recent attendance rows (newest first) — feeds the teacher's
/// calendar + summary counts. The page invalidates this after a clock-in/out
/// so the counts stay live.
final staffMyAttendanceHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  final repo = ref.watch(staffAttendanceApiRepositoryProvider);
  return repo.getMyHistory(limit: 90);
});
