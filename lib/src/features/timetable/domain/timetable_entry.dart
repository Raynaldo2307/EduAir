/// One period in a class's weekly timetable.
///
/// Mirrors a row returned by GET /api/timetable (the `timetable_entries`
/// table). Shared by every shell — admin (manage), student & teacher (view).
class TimetableEntry {
  const TimetableEntry({
    required this.id,
    required this.classId,
    required this.subject,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.shiftType,
    this.teacherId,
    this.room,
    this.teacherName,
  });

  final int id;
  final int classId;
  final int? teacherId;
  final String subject;
  final String dayOfWeek; // 'mon'..'sun'
  final String startTime; // 'HH:mm'
  final String endTime;   // 'HH:mm'
  final String shiftType; // 'morning' | 'afternoon' | 'whole_day'
  final String? room;
  final String? teacherName;

  /// "08:00 – 08:40"
  String get timeRange => '$startTime – $endTime';

  factory TimetableEntry.fromMap(Map<String, dynamic> m) {
    // The API sends TIME columns as 'HH:mm:ss' — trim to 'HH:mm' for display.
    String hhmm(Object? t) {
      final s = (t ?? '').toString();
      return s.length >= 5 ? s.substring(0, 5) : s;
    }

    final rawTeacher = (m['teacher_name'] as String?)?.trim();

    return TimetableEntry(
      id:          (m['id'] as num).toInt(),
      classId:     (m['class_id'] as num).toInt(),
      teacherId:   m['teacher_id'] == null ? null : (m['teacher_id'] as num).toInt(),
      subject:     (m['subject'] ?? '').toString(),
      dayOfWeek:   (m['day_of_week'] ?? '').toString(),
      startTime:   hhmm(m['start_time']),
      endTime:     hhmm(m['end_time']),
      shiftType:   (m['shift_type'] ?? 'whole_day').toString(),
      room:        m['room']?.toString(),
      teacherName: (rawTeacher == null || rawTeacher.isEmpty) ? null : rawTeacher,
    );
  }
}
