/// The kind of bell a slot is. A school day is not just "periods" — it has
/// devotion, breaks, lunch and a dismissal bell, and each one needs to say
/// something different when it notifies ("It's lunch" vs "Devotion starting").
///
/// String-backed (`wire`) so it joins the backend later with no translation;
/// `label` is what the UI shows. `break` is a Dart keyword, hence `breakTime`.
enum BellSlotType {
  period('period', 'Period'),
  breakTime('break', 'Break'),
  lunch('lunch', 'Lunch'),
  devotion('devotion', 'Devotion'),
  dismissal('dismissal', 'Dismissal');

  const BellSlotType(this.wire, this.label);

  final String wire;  // backend / storage value
  final String label; // UI text

  /// Only real periods hold a subject. The timetable skips everything else
  /// (you don't teach Math during lunch).
  bool get holdsSubject => this == BellSlotType.period;

  static BellSlotType fromWire(String? w) => BellSlotType.values
      .firstWhere((t) => t.wire == w, orElse: () => BellSlotType.period);
}

/// One slot in a school's bell schedule — a single "bell".
///
/// This is the SKELETON the timetable hangs on. A timetable entry does not
/// store its own times; it points at a [BellPeriod] and says "Monday, this
/// period = Math". So the times live here, once, and every class that uses
/// Period 1 shares the exact same 07:00–07:40 — they can never drift.
///
/// Designed to JOIN the existing `TimetableEntry` later:
///   • [shiftType] uses the SAME vocabulary as TimetableEntry / AttendanceDay
///     ('morning' | 'afternoon' | 'whole_day') — no translation layer needed.
///   • [startTime]/[endTime] are 'HH:mm' strings, identical to TimetableEntry —
///     zero-padded so plain string compare also sorts them correctly.
///   • [id] is the stable key a future TimetableEntry will reference.
///
/// There is deliberately NO dayOfWeek here: the bell schedule repeats every
/// day. Which day a subject is taught lives on the timetable, not the bell.
class BellPeriod {
  const BellPeriod({
    required this.id,
    required this.shiftType,
    required this.periodNumber,
    required this.label,
    required this.startTime,
    required this.endTime,
    this.type = BellSlotType.period,
  });

  /// Stable identity. The timetable will reference this.
  final int id;

  /// 'morning' | 'afternoon' | 'whole_day' — matches TimetableEntry exactly.
  final String shiftType;

  /// Ordinal within the shift (Period 1, 2, 3…). Only meaningful for real
  /// periods; breaks/devotion/dismissal ignore it.
  final int periodNumber;

  /// Human label: 'Period 1', 'Devotion', 'Lunch'.
  final String label;

  final String startTime; // 'HH:mm'
  final String endTime;   // 'HH:mm'

  /// What kind of bell this is — drives both the notification text and whether
  /// the timetable can put a subject in it.
  final BellSlotType type;

  /// "07:00 – 07:40" (matches TimetableEntry.timeRange).
  String get timeRange => '$startTime – $endTime';

  BellPeriod copyWith({
    String? shiftType,
    int? periodNumber,
    String? label,
    String? startTime,
    String? endTime,
    BellSlotType? type,
  }) {
    return BellPeriod(
      id: id,
      shiftType: shiftType ?? this.shiftType,
      periodNumber: periodNumber ?? this.periodNumber,
      label: label ?? this.label,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
    );
  }
}
