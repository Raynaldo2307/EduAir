import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/bell_schedule/data/bell_schedule_api_repository.dart';
import 'package:edu_air/src/features/bell_schedule/domain/shift.dart';
import 'package:edu_air/src/features/bell_schedule/domain/bell_period.dart';

final bellScheduleApiRepositoryProvider =
    Provider<BellScheduleApiRepository>((ref) {
  return BellScheduleApiRepository(client: ref.read(apiClientProvider));
});

/// This school's shifts. Drives the bell-schedule shift selector — 0 shifts =
/// empty state, 1 = no selector, 2+ = pick one. (Replaces the old hardcoded
/// Morning/Afternoon toggle: whole-day vs multi-shift now falls out of data.)
///
/// autoDispose is load-bearing for multi-tenancy: these shifts belong to ONE
/// school (the JWT's). On logout the shell unmounts, the last listener drops,
/// and this cache dies — so the next user never inherits the previous school's
/// shifts. Without it, a plain FutureProvider's cache outlives the user and one
/// school's data bleeds into another's session (the selector-on-whole-day bug).
final schoolShiftsProvider = FutureProvider.autoDispose<List<Shift>>((ref) {
  return ref.read(bellScheduleApiRepositoryProvider).getShifts();
});

/// One shift's bell periods. Family keyed by shift id; autoDispose so each
/// shift re-fetches fresh when selected.
final bellPeriodsByShiftProvider =
    FutureProvider.autoDispose.family<List<BellPeriod>, int>((ref, shiftId) {
  return ref.read(bellScheduleApiRepositoryProvider).getPeriods(shiftId);
});
