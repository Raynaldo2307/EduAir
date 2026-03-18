/// A single period in a student's daily timetable.
class TimetableEntry {
  const TimetableEntry({required this.time, required this.subject});

  /// Display time e.g. "07:15"
  final String time;

  /// Subject name e.g. "Mathematics"
  final String subject;
}
