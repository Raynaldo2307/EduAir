import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/features/bell_schedule/domain/bell_period.dart';

/// In-memory bell schedule (MOCK — no backend yet).
///
/// Holds every bell across every shift in one flat list; the UI filters by
/// shift with [periodsForShift]. When the backend lands this notifier is the
/// only thing that changes — it starts calling a repository instead of mutating
/// the seeded list. The screen above it never has to know.
class BellScheduleNotifier extends StateNotifier<List<BellPeriod>> {
  BellScheduleNotifier() : super(_seed);

  /// Periods for one shift, earliest first. 'HH:mm' strings sort correctly as
  /// plain strings because they are zero-padded.
  List<BellPeriod> periodsForShift(String shiftType) {
    final list =
        state.where((p) => p.shiftType == shiftType).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  int get _nextId =>
      state.isEmpty ? 1 : state.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;

  void add({
    required String shiftType,
    required int periodNumber,
    required String label,
    required String startTime,
    required String endTime,
    BellSlotType type = BellSlotType.period,
  }) {
    state = [
      ...state,
      BellPeriod(
        id: _nextId,
        shiftType: shiftType,
        periodNumber: periodNumber,
        label: label,
        startTime: startTime,
        endTime: endTime,
        type: type,
      ),
    ];
  }

  void update(BellPeriod edited) {
    state = [
      for (final p in state) if (p.id == edited.id) edited else p,
    ];
  }

  void remove(int id) {
    state = state.where((p) => p.id != id).toList();
  }
}

final bellScheduleProvider =
    StateNotifierProvider<BellScheduleNotifier, List<BellPeriod>>(
  (ref) => BellScheduleNotifier(),
);

// ─── Seed data — a realistic Jamaican shift-school day ─────────────────────────
// Morning shift 7:00–12:00, afternoon 12:00–17:00 (see CLAUDE.md §4.1).
// Whole-day schools get their own single set.
final List<BellPeriod> _seed = [
  // Morning shift
  const BellPeriod(id: 1, shiftType: 'morning', periodNumber: 0, label: 'Devotion', startTime: '07:00', endTime: '07:20', type: BellSlotType.devotion),
  const BellPeriod(id: 2, shiftType: 'morning', periodNumber: 1, label: 'Period 1', startTime: '07:20', endTime: '08:00'),
  const BellPeriod(id: 3, shiftType: 'morning', periodNumber: 2, label: 'Period 2', startTime: '08:00', endTime: '08:40'),
  const BellPeriod(id: 4, shiftType: 'morning', periodNumber: 0, label: 'Break',    startTime: '08:40', endTime: '09:00', type: BellSlotType.breakTime),
  const BellPeriod(id: 5, shiftType: 'morning', periodNumber: 3, label: 'Period 3', startTime: '09:00', endTime: '09:40'),
  const BellPeriod(id: 6, shiftType: 'morning', periodNumber: 4, label: 'Period 4', startTime: '09:40', endTime: '10:20'),
  const BellPeriod(id: 7, shiftType: 'morning', periodNumber: 0, label: 'Dismissal', startTime: '12:00', endTime: '12:00', type: BellSlotType.dismissal),

  // Afternoon shift
  const BellPeriod(id: 8,  shiftType: 'afternoon', periodNumber: 1, label: 'Period 1', startTime: '12:00', endTime: '12:40'),
  const BellPeriod(id: 9,  shiftType: 'afternoon', periodNumber: 2, label: 'Period 2', startTime: '12:40', endTime: '13:20'),
  const BellPeriod(id: 10, shiftType: 'afternoon', periodNumber: 0, label: 'Lunch',    startTime: '13:20', endTime: '13:50', type: BellSlotType.lunch),
  const BellPeriod(id: 11, shiftType: 'afternoon', periodNumber: 3, label: 'Period 3', startTime: '13:50', endTime: '14:30'),
  const BellPeriod(id: 12, shiftType: 'afternoon', periodNumber: 4, label: 'Period 4', startTime: '14:30', endTime: '15:10'),
  const BellPeriod(id: 13, shiftType: 'afternoon', periodNumber: 0, label: 'Dismissal', startTime: '17:00', endTime: '17:00', type: BellSlotType.dismissal),

  // Whole-day schools (8:00–4:00) — used when isShiftSchool is false.
  const BellPeriod(id: 14, shiftType: 'whole_day', periodNumber: 0, label: 'Devotion', startTime: '08:00', endTime: '08:20', type: BellSlotType.devotion),
  const BellPeriod(id: 15, shiftType: 'whole_day', periodNumber: 1, label: 'Period 1', startTime: '08:20', endTime: '09:05'),
  const BellPeriod(id: 16, shiftType: 'whole_day', periodNumber: 2, label: 'Period 2', startTime: '09:05', endTime: '09:50'),
  const BellPeriod(id: 17, shiftType: 'whole_day', periodNumber: 0, label: 'Break',    startTime: '09:50', endTime: '10:10', type: BellSlotType.breakTime),
  const BellPeriod(id: 18, shiftType: 'whole_day', periodNumber: 3, label: 'Period 3', startTime: '10:10', endTime: '10:55'),
  const BellPeriod(id: 19, shiftType: 'whole_day', periodNumber: 0, label: 'Lunch',    startTime: '12:15', endTime: '13:00', type: BellSlotType.lunch),
  const BellPeriod(id: 20, shiftType: 'whole_day', periodNumber: 0, label: 'Dismissal', startTime: '16:00', endTime: '16:00', type: BellSlotType.dismissal),
];
