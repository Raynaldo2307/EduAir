import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';

// ─── Date filter ──────────────────────────────────────────────────────────────

/// Holds the currently selected filter date for the attendance report.
final attendanceDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

// ─── Shift filter ─────────────────────────────────────────────────────────────

/// Shift is locked to the school's configured default shift type.
/// Reads from the logged-in user's profile — never a manual selection.
final attendanceShiftProvider = StateProvider<String>(
  (ref) => ref.read(userProvider)?.defaultShiftType ?? 'whole_day',
);

// ─── Results ──────────────────────────────────────────────────────────────────

/// Fetches school-wide attendance from the Node API for the selected date + shift.
/// autoDispose — discards cache when the admin leaves the attendance tab.
final adminAttendanceResultProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final date  = ref.watch(attendanceDateProvider);
  final shift = ref.watch(attendanceShiftProvider);
  final repo  = ref.read(attendanceApiRepositoryProvider);

  final dateKey =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  return repo.getByDateAndShift(date: dateKey, shiftType: shift);
});

// ─── Notifier ─────────────────────────────────────────────────────────────────

/// Handles admin corrections to individual attendance records.
/// On success invalidates [adminAttendanceResultProvider] so the list refreshes.
class AdminAttendanceNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AdminAttendanceNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> updateRecord(
    int id,
    String status, {
    String? note,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(attendanceApiRepositoryProvider);
      await repo.updateRecord(attendanceId: id, status: status, note: note);
      _ref.invalidate(adminAttendanceResultProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final adminAttendanceNotifierProvider = StateNotifierProvider.autoDispose<
    AdminAttendanceNotifier, AsyncValue<void>>(
  (ref) => AdminAttendanceNotifier(ref),
);
