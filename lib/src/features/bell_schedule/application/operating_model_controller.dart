import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/features/bell_schedule/application/bell_schedule_provider.dart';

/// One-shot school setup: an admin whose school has NO shifts picks an operating
/// model; the backend sets the model + seeds the shifts (guarded server-side —
/// empty schools only). This is the in-app twin of the registration choice.
///
/// State = "request in flight" (UI disables the cards + shows a spinner). The
/// method returns `String?` (null = ok, else a message). On success it
/// invalidates [schoolShiftsProvider] so the screen re-fetches the freshly
/// seeded shifts and the empty state flips to the real schedule.
class OperatingModelController extends StateNotifier<bool> {
  OperatingModelController(this._ref) : super(false);

  final Ref _ref;

  Future<String?> setup(String operatingModel) async {
    state = true;
    try {
      await _ref
          .read(bellScheduleApiRepositoryProvider)
          .setupOperatingModel(operatingModel);
      _ref.invalidate(schoolShiftsProvider);
      return null;
    } on DioException catch (e) {
      return _messageFrom(e);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    } finally {
      state = false;
    }
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) {
      return 'You do not have permission to set this up.';
    }
    return 'Could not reach the server. Check your connection.';
  }
}

final operatingModelControllerProvider =
    StateNotifierProvider<OperatingModelController, bool>(
  (ref) => OperatingModelController(ref),
);
