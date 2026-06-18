/// One of a school's shifts (a row in the backend `shifts` table).
///
/// A school's shifts are DATA, not hardcoded strings — a whole-day school has
/// one ("Whole Day"), a multi-shift school has several ("Morning", "Afternoon").
/// Each shift owns its own bell schedule ([BellPeriod]s keyed by [id]).
class Shift {
  const Shift({
    required this.id,
    required this.name,
    this.sortOrder = 0,
  });

  final int id;
  final String name;
  final int sortOrder;

  factory Shift.fromMap(Map<String, dynamic> m) {
    return Shift(
      id: (m['id'] as num).toInt(),
      name: (m['name'] ?? '').toString(),
      sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
