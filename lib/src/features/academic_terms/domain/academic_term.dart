/// One of a school's academic terms — a row in the backend `academic_terms`.
///
/// A named reporting window with a start and end date (e.g. "Term 1",
/// Sep 1 – Dec 13). The CURRENT term isn't a field — the backend derives it
/// (the active term whose span contains today), so there's no stale flag to
/// carry around on the client either.
class AcademicTerm {
  const AcademicTerm({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  final int id;
  final String name;
  final DateTime startDate; // date-only (local midnight)
  final DateTime endDate;

  factory AcademicTerm.fromMap(Map<String, dynamic> m) {
    return AcademicTerm(
      id: (m['id'] as num).toInt(),
      name: (m['name'] ?? '').toString(),
      // API sends DATE as 'YYYY-MM-DD' (DATE_FORMAT'd); DateTime.parse accepts it.
      startDate: DateTime.parse(m['start_date'].toString()),
      endDate: DateTime.parse(m['end_date'].toString()),
    );
  }

  /// 'YYYY-MM-DD' — the wire format the backend expects and returns. Used when
  /// sending a DateTime back up (create/update).
  static String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
