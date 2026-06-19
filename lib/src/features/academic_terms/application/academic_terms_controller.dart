import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/features/academic_terms/application/academic_terms_provider.dart';

/// Write side of a school's academic terms (add / edit / delete). Same shape as
/// BellScheduleController: state is a `bool` "write in flight" the UI watches to
/// disable Save; methods return `String?` (null = ok, else a message). After a
/// successful write it invalidates BOTH the list and the current-term provider
/// (a new/edited term can change which one contains today) so the screen
/// re-fetches the server's truth instead of guessing.
class AcademicTermsController extends StateNotifier<bool> {
  AcademicTermsController(this._ref) : super(false);

  final Ref _ref;

  Future<String?> addTerm({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _run(() => _ref
        .read(academicTermsApiRepositoryProvider)
        .create(name: name, startDate: startDate, endDate: endDate));
  }

  Future<String?> editTerm(
    int id, {
    String? name,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _run(() => _ref
        .read(academicTermsApiRepositoryProvider)
        .update(id, name: name, startDate: startDate, endDate: endDate));
  }

  Future<String?> removeTerm(int id) {
    return _run(
        () => _ref.read(academicTermsApiRepositoryProvider).delete(id));
  }

  Future<String?> _run(Future<void> Function() action) async {
    state = true;
    try {
      await action();
      _ref.invalidate(schoolTermsProvider);
      _ref.invalidate(currentTermProvider);
      return null;
    } on DioException catch (e) {
      return _messageFrom(e);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    } finally {
      state = false;
    }
  }

  /// Prefer the backend's message ("These dates overlap an existing term...",
  /// "end_date must be after start_date.") over a generic one — it's the source
  /// of truth for why a write failed. Fall back by status, then a catch-all.
  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) {
      return 'You do not have permission to change terms.';
    }
    if (code == 404) return 'That term no longer exists.';
    return 'Could not reach the server. Check your connection.';
  }
}

final academicTermsControllerProvider =
    StateNotifierProvider<AcademicTermsController, bool>(
  (ref) => AcademicTermsController(ref),
);
