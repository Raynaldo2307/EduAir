import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/features/bell_schedule/application/bell_schedule_provider.dart';
import 'package:edu_air/src/features/bell_schedule/data/bell_schedule_api_repository.dart';
import 'package:edu_air/src/features/bell_schedule/domain/bell_period.dart';

/// Write side of the bell schedule (add / edit / delete a bell).
///
/// State is a simple `bool` = "a write is in flight" — the UI watches it to
/// disable the save button and show a spinner. Each method returns `String?`:
/// `null` on success, or a user-facing error message on failure (same
/// convention as StudentAttendanceController). After any successful write it
/// invalidates `bellPeriodsByShiftProvider(shiftId)` so the list re-fetches and
/// the screen shows the new truth — we never mutate a local copy by hand.
class BellScheduleController extends StateNotifier<bool> {
  BellScheduleController(this._ref) : super(false);

  final Ref _ref;

  BellScheduleApiRepository get _repo =>
      _ref.read(bellScheduleApiRepositoryProvider);

  Future<String?> addPeriod({
    required int shiftId,
    required int position,
    required String label,
    required String startTime,
    required String endTime,
    BellSlotType kind = BellSlotType.teaching,
  }) {
    return _run(shiftId, () => _repo.createPeriod(
          shiftId: shiftId,
          position: position,
          label: label,
          startTime: startTime,
          endTime: endTime,
          kind: kind,
        ));
  }

  Future<String?> editPeriod(
    int id, {
    required int shiftId,
    int? position,
    String? label,
    String? startTime,
    String? endTime,
    BellSlotType? kind,
  }) {
    return _run(shiftId, () => _repo.updatePeriod(
          id,
          position: position,
          label: label,
          startTime: startTime,
          endTime: endTime,
          kind: kind,
        ));
  }

  Future<String?> removePeriod(int id, {required int shiftId}) {
    return _run(shiftId, () => _repo.deletePeriod(id));
  }

  /// Runs one write: flips the busy flag, refreshes the shift's list on success,
  /// and turns any failure into a message. Centralised so add/edit/delete all
  /// behave the same — one place to change the error handling.
  Future<String?> _run(int shiftId, Future<void> Function() action) async {
    state = true;
    try {
      await action();
      _ref.invalidate(bellPeriodsByShiftProvider(shiftId));
      return null;
    } on DioException catch (e) {
      return _messageFrom(e);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    } finally {
      state = false;
    }
  }

  /// The backend is the source of truth for validation, so prefer its message
  /// ("end_time must be after start_time", "Shift not found.") over a generic
  /// one. Fall back by status, then to a catch-all.
  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) {
      return 'You do not have permission to change the bell schedule.';
    }
    if (code == 404) return 'That bell no longer exists.';
    return 'Could not reach the server. Check your connection.';
  }
}

/// State = is a write in flight. UI watches this to disable Save + show a
/// spinner; it calls the notifier's methods to do the actual work.
final bellScheduleControllerProvider =
    StateNotifierProvider<BellScheduleController, bool>(
  (ref) => BellScheduleController(ref),
);
