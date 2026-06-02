import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/admin/clockin/application/clockin_records_provider.dart';

// ─── Notifier ─────────────────────────────────────────────────────────────────

/// Handles admin/principal corrections to individual attendance records.
/// On success it invalidates [clockinRecordsProvider] so the merged Attendance
/// list refreshes with the corrected status.
class AdminAttendanceNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AdminAttendanceNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> updateRecord(
    int id,
    String status, {
    String? lateReasonCode,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(attendanceApiRepositoryProvider);
      await repo.updateRecord(
        attendanceId: id,
        status: status,
        lateReasonCode: lateReasonCode,
        note: note,
      );
      _ref.invalidate(clockinRecordsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final adminAttendanceNotifierProvider =
    StateNotifierProvider<AdminAttendanceNotifier, AsyncValue<void>>(
  (ref) => AdminAttendanceNotifier(ref),
);
