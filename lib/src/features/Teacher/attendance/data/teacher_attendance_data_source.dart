import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/teacher/attendance/domain/teacher_attendance_models.dart';
import 'package:edu_air/src/models/app_user.dart';

class TeacherAttendanceDataSource {
  TeacherAttendanceDataSource({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> _attendanceCollection(
    String schoolId,
  ) {
    return _db.collection('schools').doc(schoolId).collection('attendance');
  }

  Future<List<TeacherAttendanceStudent>> fetchStudentsForClass({
    required String schoolId,
    required TeacherClassOption classOption,
  }) async {
    final classField = classOption.classId.isNotEmpty ? 'classId' : 'className';
    final classValue =
        classOption.classId.isNotEmpty ? classOption.classId : classOption.className;

    final snapshot = await _usersCollection
        .where('schoolId', isEqualTo: schoolId)
        .where('role', isEqualTo: 'student')
        .where(classField, isEqualTo: classValue)
        .get();

    return snapshot.docs
        .map((doc) => AppUser.fromMap(doc.id, doc.data()))
        .map(TeacherAttendanceStudent.fromUser)
        .toList();
  }

  Future<Map<String, AttendanceStatus>> fetchAttendanceForClassDate({
    required String schoolId,
    required TeacherClassOption classOption,
    required String dateKey,
    String? shiftType,
  }) async {
    final classField = classOption.classId.isNotEmpty ? 'classId' : 'className';
    final classValue =
        classOption.classId.isNotEmpty ? classOption.classId : classOption.className;

    Query<Map<String, dynamic>> query = _attendanceCollection(schoolId)
        .where('date', isEqualTo: dateKey)
        .where(classField, isEqualTo: classValue);

    if (shiftType != null && shiftType.isNotEmpty) {
      query = query.where('shiftType', isEqualTo: shiftType);
    }

    final snapshot = await query.get();
    final result = <String, AttendanceStatus>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final studentUid = (data['studentUid'] ?? '').toString();
      if (studentUid.isEmpty) continue;
      result[studentUid] = _statusFromString(data['status'] as String?);
    }

    return result;
  }

  Future<void> commitAttendanceBatch({
    required String schoolId,
    required List<TeacherAttendanceEntry> entries,
  }) async {
    if (entries.isEmpty) return;

    final batch = _db.batch();
    final collection = _attendanceCollection(schoolId);

    for (final entry in entries) {
      final docRef = collection.doc(entry.docId);
      final data = entry.toFirestoreMap();

      data['takenAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      batch.set(docRef, data, SetOptions(merge: true));
    }

    await batch.commit();
  }

  AttendanceStatus _statusFromString(String? value) {
    if (value == null || value.isEmpty) {
      return AttendanceStatus.present;
    }
    return AttendanceStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AttendanceStatus.absent,
    );
  }
}
