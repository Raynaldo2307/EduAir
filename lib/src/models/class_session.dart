class ClassSession {
  const ClassSession({
    this.id,
    required this.subjectName,
    this.subjectCode,
    required this.groupName,
    required this.teacherName, // 👈 we keep this
    required this.startTime,
    required this.endTime,
    required this.room,
    this.isOnline = false,
    this.onlineLink,
  });

  final String? id;
  final String subjectName;
  final String? subjectCode;
  final String groupName;
  final String teacherName; // e.g. "Mr Brown"
  final DateTime startTime;
  final DateTime endTime;
  final String room;
  final bool isOnline;
  final String? onlineLink;
}
