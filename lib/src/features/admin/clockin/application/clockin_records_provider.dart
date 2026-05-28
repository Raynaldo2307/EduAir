import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_air/src/core/app_providers.dart';

final clockinDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// null = show all shifts
final clockinShiftProvider = StateProvider<String?>((ref) => null);

// null = show all statuses
final clockinStatusFilterProvider = StateProvider<String?>((ref) => null);

final clockinRecordsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final date  = ref.watch(clockinDateProvider);
  final shift = ref.watch(clockinShiftProvider);
  final repo  = ref.read(attendanceApiRepositoryProvider);

  final dateKey =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  final rows = await repo.getByDate(date: dateKey, shiftType: shift);

  // Client-side status filter — avoids a separate API call
  final statusFilter = ref.watch(clockinStatusFilterProvider);
  if (statusFilter == null) return rows;
  return rows.where((r) => r['status'] == statusFilter).toList();
});
