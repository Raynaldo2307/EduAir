import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/models/app_user.dart';

class TeacherClassOption {
  const TeacherClassOption({
    required this.classId,
    required this.className,
    this.gradeLevel,
  });

  final String classId;
  final String className;
  final int? gradeLevel;

  @override
  bool operator ==(Object other) {
    return other is TeacherClassOption &&
        other.classId == classId &&
        other.className == className;
  }

  @override
  int get hashCode => Object.hash(classId, className);
}

class TeacherAttendanceStudent {
  const TeacherAttendanceStudent({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.classId,
    this.className,
    this.gradeLevel,
    this.sex,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;
  final String? classId;
  final String? className;
  final int? gradeLevel;
  final String? sex;

  String get initials {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'U';
    return trimmed.substring(0, 1).toUpperCase();
  }

  factory TeacherAttendanceStudent.fromUser(AppUser user) {
    return TeacherAttendanceStudent(
      uid: user.uid,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      classId: user.classId,
      className: user.className,
      gradeLevel: user.gradeLevelNumber,
      sex: user.sex ?? user.gender,
    );
  }
}

class TeacherAttendanceEntry {
  TeacherAttendanceEntry({
    required this.schoolId,
    required this.dateKey,
    required this.status,
    required this.student,
    required this.classOption,
    required this.takenByUid,
    this.shiftType,
    this.subjectId,
    this.subjectName,
    this.periodId,
  });

  final String schoolId;
  final String dateKey;
  final AttendanceStatus status;
  final TeacherAttendanceStudent student;
  final TeacherClassOption classOption;
  final String takenByUid;
  final String? shiftType;
  final String? subjectId;
  final String? subjectName;
  final String? periodId;

  String get docId => '${dateKey}_${student.uid}';

  String get resolvedClassId =>
      (student.classId != null && student.classId!.isNotEmpty)
          ? student.classId!
          : classOption.classId;

  String get resolvedClassName =>
      (student.className != null && student.className!.isNotEmpty)
          ? student.className!
          : classOption.className;

  int? get resolvedGradeLevel => student.gradeLevel ?? classOption.gradeLevel;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'schoolId': schoolId,
      'studentUid': student.uid,
      'classId': resolvedClassId,
      'className': resolvedClassName,
      if (resolvedGradeLevel != null) 'gradeLevel': resolvedGradeLevel,
      'date': dateKey,
      'status': status.name,
      'takenByUid': takenByUid,
      if (subjectId != null) 'subjectId': subjectId,
      if (subjectName != null) 'subjectName': subjectName,
      if (periodId != null) 'periodId': periodId,
      if (shiftType != null) 'shiftType': shiftType,
    };
  }
}
