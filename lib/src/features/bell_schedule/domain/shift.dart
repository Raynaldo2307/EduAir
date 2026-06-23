/// One of a school's shifts (a row in the backend `shifts` table).
///
/// A school's shifts are DATA, not hardcoded strings — a whole-day school has
/// one ("Whole Day"), a multi-shift school has several ("Morning", "Afternoon").
/// Each shift owns its own bell schedule ([BellPeriod]s keyed by [id]).
class Shift {
  const Shift({
    required this.id,
    required this.name,
    this.type,
    this.sortOrder = 0,
  });

  final int id;
  final String name;

  /// Machine-readable type — 'morning' | 'afternoon' | 'whole_day' — matching a
  /// student/teacher's currentShift. Null for a shift not yet typed (the bell
  /// merge falls back to classes-only rather than guessing). The display name
  /// ([name]) is for humans and may be relabelled; [type] is the stable key.
  final String? type;
  final int sortOrder;

  factory Shift.fromMap(Map<String, dynamic> m) {
    return Shift(
      id: (m['id'] as num).toInt(),
      name: (m['name'] ?? '').toString(),
      type: m['shift_type']?.toString(),
      sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
