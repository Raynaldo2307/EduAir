import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/teacher/attendance/domain/teacher_attendance_models.dart';
import 'package:edu_air/src/models/app_user.dart';

/// Low-level Firestore access for **teacher-driven attendance**.
///
/// Responsibilities:
/// - Query students for a given class.
/// - Query existing attendance for a class + date + shift.
/// - Save a batch of teacher marks with denormalized fields (sex, gradeLevel, shiftType)
///   and an audit history subcollection.
/// - Provide monthly aggregates for SF4-style reporting.
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

  /// Fetch all students in a given class/form for this teacher.
  Future<List<TeacherAttendanceStudent>> fetchStudentsForClass({
    required String schoolId,
    required TeacherClassOption classOption,
  }) async {
    final classField = classOption.classId.isNotEmpty ? 'classId' : 'className';
    final classValue = classOption.classId.isNotEmpty
        ? classOption.classId
        : classOption.className;

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

  /// Fetch an attendance map for one class + date + shift.
  ///
  /// Returns a map of:
  ///   { studentUid: AttendanceStatus }
  Future<Map<String, AttendanceStatus>> fetchAttendanceForClassDate({
    required String schoolId,
    required TeacherClassOption classOption,
    required String dateKey,
    String? shiftType,
  }) async {
    final classField = classOption.classId.isNotEmpty ? 'classId' : 'className';
    final classValue = classOption.classId.isNotEmpty
        ? classOption.classId
        : classOption.className;
    final effectiveShiftType = AttendanceDay.normalizeShiftType(shiftType);

    final query = _attendanceCollection(schoolId)
        .where('date', isEqualTo: dateKey)
        .where(classField, isEqualTo: classValue)
        .where('shiftType', isEqualTo: effectiveShiftType);

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

  /// Save a batch of teacher marks in a single Firestore batch.
  ///
  /// - Stamps sex, gradeLevel, shiftType onto each attendance doc.
  /// - Writes `takenAt` (for new docs) and `updatedAt` (for all).
  /// - Appends a history document when the status changes.
  ///
  /// Returns [AttendanceBatchResult] so the UI can react in low-connectivity cases.
  Future<AttendanceBatchResult> saveAttendanceBatch({
    required String schoolId,
    required List<TeacherAttendanceEntry> entries,
  }) async {
    if (entries.isEmpty) {
      return const AttendanceBatchResult(
        totalEntries: 0,
        successCount: 0,
        failureCount: 0,
        failedStudentUids: <String>[],
      );
    }

    final collection = _attendanceCollection(schoolId);

    // Pre-resolve existing docs + student fields so we can:
    // - know if each doc is new
    // - know previousStatus for audit trail
    // - stamp sex + gradeLevel
    final payloads = await Future.wait(
      entries.map((entry) async {
        final docRef = collection.doc(entry.docId);
        final snapshot = await docRef.get();
        final resolvedFields = await _resolveEntryFields(entry);
        final previousStatus = _statusFromStringOrNull(
          snapshot.data()?['status'] as String?,
        );

        return _AttendanceBatchPayload(
          entry: entry,
          docRef: docRef,
          isNew: !snapshot.exists,
          previousStatus: previousStatus,
          resolvedSex: resolvedFields.sex,
          resolvedGradeLevel: resolvedFields.gradeLevel,
        );
      }),
    );

    final batch = _db.batch();

    try {
      for (final payload in payloads) {
        final entry = payload.entry;
        final data = entry.toFirestoreMap();

        // Stamp denormalized fields for MoEYI / analytics.
        data['sex'] = payload.resolvedSex;
        data['gradeLevel'] = payload.resolvedGradeLevel;
        data['shiftType'] = entry.resolvedShiftType;
        data['source'] = 'teacherBatch';

        // Audit timestamps.
        if (payload.isNew) {
          data['takenAt'] = FieldValue.serverTimestamp();
        }
        data['updatedAt'] = FieldValue.serverTimestamp();

        // Upsert the attendance doc.
        batch.set(payload.docRef, data, SetOptions(merge: true));

        // Audit history: only when new or status actually changed.
        if (payload.isNew || payload.previousStatus != entry.status) {
          final historyRef = payload.docRef.collection('history').doc();
          batch.set(historyRef, {
            'previousStatus': payload.previousStatus?.name,
            'newStatus': entry.status.name,
            'changedByUid': entry.takenByUid, // teacher uid
            'serverTimestamp': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      // In Firestore, a batch is all-or-nothing.
      return AttendanceBatchResult(
        totalEntries: entries.length,
        successCount: entries.length,
        failureCount: 0,
        failedStudentUids: const [],
      );
    } on FirebaseException {
      // If commit fails, assume nothing was written.
      final failedUids = entries.map((e) => e.student.uid).toSet().toList();
      return AttendanceBatchResult(
        totalEntries: entries.length,
        successCount: 0,
        failureCount: entries.length,
        failedStudentUids: failedUids,
      );
    } catch (_) {
      // Catch-all: treat as total failure.
      final failedUids = entries.map((e) => e.student.uid).toSet().toList();
      return AttendanceBatchResult(
        totalEntries: entries.length,
        successCount: 0,
        failureCount: entries.length,
        failedStudentUids: failedUids,
      );
    }
  }

  /// Monthly aggregation for one class, one school, one shift.
  ///
  /// This powers SF4-style reporting and AI "declining attendance" signals.
  Future<ClassMonthlyAttendanceSummary> fetchMonthlyClassSummary({
    required String schoolId,
    required TeacherClassOption classOption,
    required int year,
    required int month,
    String? shiftType,
  }) async {
    final effectiveShiftType = AttendanceDay.normalizeShiftType(shiftType);

    // Compute month range: [firstDay, lastDay]
    final firstDay = DateTime(year, month, 1);
    final firstDayKey = AttendanceDay.dateKeyFor(firstDay);
    final lastDay = DateTime(
      year,
      month + 1,
      0,
    ); // day 0 = last day of prev month
    final lastDayKey = AttendanceDay.dateKeyFor(lastDay);

    final classField = classOption.classId.isNotEmpty ? 'classId' : 'className';
    final classValue = classOption.classId.isNotEmpty
        ? classOption.classId
        : classOption.className;

    final snapshot = await _attendanceCollection(schoolId)
        .where('date', isGreaterThanOrEqualTo: firstDayKey)
        .where('date', isLessThanOrEqualTo: lastDayKey)
        .where(classField, isEqualTo: classValue)
        .where('shiftType', isEqualTo: effectiveShiftType)
        .get();

    int totalMarked = 0;
    int totalPresentLike = 0;
    int totalAbsent = 0;
    int totalExcused = 0;

    final schoolDayKeys = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final dateKey = (data['date'] ?? '').toString();
      if (dateKey.isEmpty) continue;

      schoolDayKeys.add(dateKey);
      totalMarked += 1;

      final status = _statusFromString(data['status'] as String?);
      switch (status) {
        case AttendanceStatus.early:
        case AttendanceStatus.late:
        case AttendanceStatus.present:
          totalPresentLike += 1;
          break;
        case AttendanceStatus.absent:
          totalAbsent += 1;
          break;
        case AttendanceStatus.excused:
          totalExcused += 1;
          break;
      }
    }

    return ClassMonthlyAttendanceSummary(
      schoolId: schoolId,
      classOption: classOption,
      year: year,
      month: month,
      shiftType: effectiveShiftType,
      totalMarkedRecords: totalMarked,
      totalPresentLike: totalPresentLike,
      totalAbsent: totalAbsent,
      totalExcused: totalExcused,
      distinctSchoolDays: schoolDayKeys.length,
    );
  }

  /// Resolve sex + gradeLevel for a student, preferring data from the
  /// [TeacherAttendanceEntry] and falling back to the AppUser profile.
  Future<_ResolvedStudentFields> _resolveEntryFields(
    TeacherAttendanceEntry entry,
  ) async {
    String? resolvedSex = _normalizeSex(entry.resolvedSex);
    int? resolvedGradeLevel = entry.resolvedGradeLevel;

    if (resolvedSex != null && resolvedGradeLevel != null) {
      return _ResolvedStudentFields(
        sex: resolvedSex,
        gradeLevel: resolvedGradeLevel,
      );
    }

    final profile = await _fetchUserProfile(entry.student.uid);
    resolvedSex ??= _normalizeSex(profile?.sex);
    resolvedGradeLevel ??= profile?.gradeLevelNumber;

    return _ResolvedStudentFields(
      sex: resolvedSex,
      gradeLevel: resolvedGradeLevel,
    );
  }

  Future<AppUser?> _fetchUserProfile(String studentUid) async {
    final snapshot = await _usersCollection.doc(studentUid).get();
    if (!snapshot.exists) return null;
    return AppUser.fromMap(studentUid, snapshot.data());
  }

  String? _normalizeSex(String? value) {
    final trimmedValue = value?.trim();
    if (trimmedValue == null || trimmedValue.isEmpty) return null;
    final upper = trimmedValue.toUpperCase();
    if (upper == 'M' || upper == 'MALE') return 'M';
    if (upper == 'F' || upper == 'FEMALE') return 'F';
    return null;
  }

  /// Safe parser: if value is null/empty/unknown, default to PRESENT so we
  /// never accidentally mark a student ABSENT because of bad data.
  AttendanceStatus _statusFromString(String? value) {
    if (value == null || value.isEmpty) {
      return AttendanceStatus.present;
    }
    for (final status in AttendanceStatus.values) {
      if (status.name == value) return status;
    }
    return AttendanceStatus.present;
  }

  /// Nullable version used when we care about "no previous status".
  AttendanceStatus? _statusFromStringOrNull(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final status in AttendanceStatus.values) {
      if (status.name == value) return status;
    }
    return null;
  }
}

class _ResolvedStudentFields {
  const _ResolvedStudentFields({required this.sex, required this.gradeLevel});

  final String? sex;
  final int? gradeLevel;
}

class _AttendanceBatchPayload {
  const _AttendanceBatchPayload({
    required this.entry,
    required this.docRef,
    required this.isNew,
    required this.previousStatus,
    required this.resolvedSex,
    required this.resolvedGradeLevel,
  });

  final TeacherAttendanceEntry entry;
  final DocumentReference<Map<String, dynamic>> docRef;
  final bool isNew;
  final AttendanceStatus? previousStatus;
  final String? resolvedSex;
  final int? resolvedGradeLevel;
}
