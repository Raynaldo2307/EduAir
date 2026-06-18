/// The kind of bell a slot is. Wire values MUST match the backend
/// `bell_periods.kind` enum exactly (the DB is the source of truth) so they
/// join with no translation — the same wire-value discipline as before.
///
/// Backend VALID_KINDS = teaching · devotion · assembly · break · lunch · dismissal
enum BellSlotType {
  teaching('teaching', 'Class period'),
  devotion('devotion', 'Devotion'),
  assembly('assembly', 'Assembly'),
  breakTime('break', 'Break'),
  lunch('lunch', 'Lunch'),
  dismissal('dismissal', 'Dismissal');

  const BellSlotType(this.wire, this.label);

  final String wire;  // backend `kind` value
  final String label; // UI text

  /// Only teaching periods hold a subject; the timetable skips the rest.
  bool get holdsSubject => this == BellSlotType.teaching;

  /// Parse a backend `kind`. Defaults to teaching so a new/unknown value never
  /// silently mismaps real seeded data into a break.
  static BellSlotType fromWire(String? w) => BellSlotType.values
      .firstWhere((t) => t.wire == w, orElse: () => BellSlotType.teaching);
}

/// One slot in a shift's bell schedule — a row in the backend `bell_periods`.
///
/// Belongs to a [shiftId] (NOT a shift string) — the schedule is per-shift.
/// [position] orders the slots within the shift; [startTime]/[endTime] are
/// 'HH:mm' strings (the API trims TIME columns for us).
class BellPeriod {
  const BellPeriod({
    required this.id,
    required this.shiftId,
    required this.position,
    required this.label,
    required this.startTime,
    required this.endTime,
    this.kind = BellSlotType.teaching,
  });

  final int id;
  final int shiftId;
  final int position;
  final String label;
  final String startTime; // 'HH:mm'
  final String endTime;   // 'HH:mm'
  final BellSlotType kind;

  /// "07:00 – 07:40"
  String get timeRange => '$startTime – $endTime';

  factory BellPeriod.fromMap(Map<String, dynamic> m) {
    // API sends TIME as 'HH:mm' already, but trim defensively.
    String hhmm(Object? t) {
      final s = (t ?? '').toString();
      return s.length >= 5 ? s.substring(0, 5) : s;
    }

    return BellPeriod(
      id: (m['id'] as num).toInt(),
      shiftId: (m['shift_id'] as num).toInt(),
      position: (m['position'] as num?)?.toInt() ?? 0,
      label: (m['label'] ?? '').toString(),
      startTime: hhmm(m['start_time']),
      endTime: hhmm(m['end_time']),
      kind: BellSlotType.fromWire(m['kind']?.toString()),
    );
  }
}
