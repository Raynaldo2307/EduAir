// lib/src/features/attendance/data/attendance_firestore_source.dart

import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import 'package:edu_air/src/features/attendance/domain/attendance_exceptions.dart';
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/models/app_user.dart';

/// Low-level Firestore access for attendance.
///
/// - Knows the path: schools/{schoolId}/attendance/{YYYY-MM-DD}_{shiftType}_{studentUid}
/// - Maps AttendanceDay <-> Firestore document
/// - Does NOT contain UI or business rules (no early/late logic).
class AttendanceFirestoreSource {
  final FirebaseFirestore _db;

  AttendanceFirestoreSource({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  /// Scope attendance under the school for multi-school clarity.
  /// Path: schools/{schoolId}/attendance
  CollectionReference<Map<String, dynamic>> _daysCollection(String schoolId) {
    return _db.collection('schools').doc(schoolId).collection('attendance');
  }

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _db.collection('users');

  /// Document ID: "{dateKey}_{shiftType}_{studentUid}"
  String _docIdFor(String dateKey, String shiftType, String studentUid) {
    return AttendanceDay.docIdFor(
      dateKey: dateKey,
      shiftType: shiftType,
      studentUid: studentUid,
    );
  }

  /// Recover the dateKey ("YYYY-MM-DD") from a composite docId.
  ///
  /// Expected format: "{dateKey}_{shiftType}_{studentUid}".
  /// We only care about the first segment (dateKey) as a fallback when
  /// the 'date' field is missing.
  String _dateKeyFromDocId(String docId) {
    final parts = docId.split('_');
    if (parts.isEmpty) return docId;
    return parts.first; // "2025-01-13" from "2025-01-13_morning_abc123"
  }

  /// schools/{schoolId}/attendance/{YYYY-MM-DD}_{shiftType}_{studentUid}
  DocumentReference<Map<String, dynamic>> _dayDoc({
    required String schoolId,
    required String studentUid,
    required String dateKey,
    required String shiftType,
  }) {
    return _daysCollection(
      schoolId,
    ).doc(_docIdFor(dateKey, shiftType, studentUid));
  }

  /// Get a single day for a student.
  ///
  /// Returns null if the document does not exist.
  Future<AttendanceDay?> fetchDay({
    required String schoolId,
    required String studentUid,
    required String dateKey,
    String? shiftType,
  }) async {
    final effectiveShiftType = AttendanceDay.normalizeShiftType(shiftType);
    try {
      final doc = await _dayDoc(
        schoolId: schoolId,
        studentUid: studentUid,
        dateKey: dateKey,
        shiftType: effectiveShiftType,
      ).get();

      if (!doc.exists) return null;
      return _fromDoc(studentUid: studentUid, doc: doc);
    } on FirebaseException catch (e, st) {
      _handleFirestoreError(e, st);
    } on PlatformException catch (e, st) {
      _handleFirestoreError(e, st);
    } catch (e, st) {
      _handleFirestoreError(e, st);
    }
  }

  /// Save/overwrite a day for a student.
  ///
  /// - Uses [day.dateKey] + shiftType + studentUid as the document ID.
  /// - Caller is responsible for business rules (status, lateReason, etc.).
  Future<void> saveDay({
    required String schoolId,
    required String studentUid,
    required AttendanceDay day,
    bool? isNew,
    String? changedByUid,
  }) async {
    // Small safety check: make sure the model's uid matches the Firestore path.
    assert(
      day.studentUid == studentUid,
      'AttendanceDay.studentUid (${day.studentUid}) must match path studentUid ($studentUid)',
    );

    final effectiveShiftType = AttendanceDay.normalizeShiftType(day.shiftType);
    try {
      final docRef = _dayDoc(
        schoolId: schoolId,
        studentUid: studentUid,
        dateKey: day.dateKey,
        shiftType: effectiveShiftType,
      );

      // Read existing status when needed so we can write immutable history.
      DocumentSnapshot<Map<String, dynamic>>? snapshot;
      AttendanceStatus? previousStatus;
      bool effectiveIsNew;

      if (isNew == true) {
        effectiveIsNew = true;
      } else {
        snapshot = await docRef.get();
        effectiveIsNew = !snapshot.exists;
        if (snapshot.exists) {
          previousStatus = _statusFromStringOrNull(
            snapshot.data()?['status'] as String?,
          );
        }
      }

      final resolvedFields = await _resolveStudentFields(
        studentUid: studentUid,
        sex: day.sex,
        gradeLevel: day.gradeLevel,
      );

      await docRef.set(
        _toMap(
          day,
          shiftType: effectiveShiftType,
          sex: resolvedFields.sex,
          gradeLevel: resolvedFields.gradeLevel,
          isNew: effectiveIsNew,
        ),
        SetOptions(merge: true),
      );

      final effectiveChangedByUid = _resolveChangedByUid(
        changedByUid: changedByUid,
        takenByUid: day.takenByUid,
        studentUid: studentUid,
      );

      if (effectiveIsNew || previousStatus != day.status) {
        await docRef.collection('history').add({
          'previousStatus': previousStatus?.name,
          'newStatus': day.status.name,
          'changedByUid': effectiveChangedByUid,
          'serverTimestamp': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (e, st) {
      _handleFirestoreError(e, st);
    } on PlatformException catch (e, st) {
      _handleFirestoreError(e, st);
    } catch (e, st) {
      _handleFirestoreError(e, st);
    }
  }

  /// Fetch all days for a student in [from]..[to] (inclusive).
  ///
  /// Dates are normalized to "YYYY-MM-DD" in the same way as
  /// [AttendanceDay.dateKeyFor].
  /// Results are ordered descending by date (most recent first).
  ///
  /// 🔹 Firestore index note:
  /// You will need a composite index on:
  ///   - collection: schools/{schoolId}/attendance
  ///   - fields: studentUid (==), shiftType (==), date (range/orderBy)
  Future<List<AttendanceDay>> fetchDaysInRange({
    required String schoolId,
    required String studentUid,
    required DateTime from,
    required DateTime to,
    String? shiftType,
  }) async {
    // Ensure from <= to
    DateTime start = from;
    DateTime end = to;
    if (end.isBefore(start)) {
      final tmp = start;
      start = end;
      end = tmp;
    }

    final fromKey = AttendanceDay.dateKeyFor(start);
    final toKey = AttendanceDay.dateKeyFor(end);
    final effectiveShiftType = AttendanceDay.normalizeShiftType(shiftType);

    try {
      final query = await _daysCollection(schoolId)
          .where('studentUid', isEqualTo: studentUid)
          .where('shiftType', isEqualTo: effectiveShiftType)
          .where('date', isGreaterThanOrEqualTo: fromKey)
          .where('date', isLessThanOrEqualTo: toKey)
          .orderBy('date', descending: true)
          .get();

      return query.docs
          .map((doc) => _fromDoc(studentUid: studentUid, doc: doc))
          .toList();
    } on FirebaseException catch (e, st) {
      _handleFirestoreError(e, st);
    } on PlatformException catch (e, st) {
      _handleFirestoreError(e, st);
    } catch (e, st) {
      _handleFirestoreError(e, st);
    }
  }

  /// Convenience helper: fetch the most recent [limit] days for a student,
  /// ordered by date descending (today first).
  ///
  /// NOTE: This uses DateTime.now(). If you later standardize on
  /// AttendanceService.schoolNow() for timezone correctness, you can move
  /// the "what is today?" logic up to the service and call [fetchDaysInRange].
  Future<List<AttendanceDay>> fetchRecentDays({
    required String schoolId,
    required String studentUid,
    int limit = 14,
    String? shiftType,
  }) {
    final now = DateTime.now();
    // For "recent N days" we can simply go back (limit - 1) days from today.
    final from = now.subtract(Duration(days: limit - 1));

    return fetchDaysInRange(
      schoolId: schoolId,
      studentUid: studentUid,
      from: from,
      to: now,
      shiftType: shiftType,
    );
  }

  // ---------------------------------------------------------------------------
  // Mapping helpers
  // ---------------------------------------------------------------------------

  AttendanceDay _fromDoc({
    required String studentUid,
    required DocumentSnapshot<Map<String, dynamic>> doc,
  }) {
    final data = doc.data() ?? const <String, dynamic>{};

    final status = _statusFromString(data['status'] as String?);

    final clockInTs = data['clockInAt'] as Timestamp?;
    final clockOutTs = data['clockOutAt'] as Timestamp?;

    final clockInLoc = _locationFromDynamic(data['clockInLoc']);
    final clockOutLoc = _locationFromDynamic(data['clockOutLoc']);

    final takenAtTs = data['takenAt'] as Timestamp?;
    final updatedAtTs = data['updatedAt'] as Timestamp?;

    final rawGradeLevel = data['gradeLevel'];
    final gradeLevel = rawGradeLevel is int
        ? rawGradeLevel
        : int.tryParse(rawGradeLevel?.toString() ?? '');
    final sex = _normalizeSex(data['sex']?.toString());
    final shiftType = AttendanceDay.normalizeShiftType(
      data['shiftType']?.toString(),
    );

    // NEW (with safe default to false if field is missing)
    final isEarlyLeave = (data['isEarlyLeave'] as bool?) ?? false;
    final isOvertime = (data['isOvertime'] as bool?) ?? false;

    // Source + deviceId (backward-compat: default to studentSelf for old docs)
    final source = _sourceFromString(data['source'] as String?);
    final deviceId = data['deviceId'] as String?;

    return AttendanceDay(
      dateKey: data['date'] as String? ?? _dateKeyFromDocId(doc.id),
      studentUid: studentUid,
      status: status,
      schoolId: data['schoolId'] as String?,
      classId: data['classId'] as String?,
      className: data['className'] as String?,
      gradeLevel: gradeLevel,
      sex: sex,
      clockInAt: clockInTs?.toDate(),
      clockOutAt: clockOutTs?.toDate(),
      clockInLocation: clockInLoc,
      clockOutLocation: clockOutLoc,
      lateReason: data['lateReason'] as String?,
      takenByUid: data['takenByUid'] as String?,
      takenAt: takenAtTs?.toDate(),
      updatedAt: updatedAtTs?.toDate(),
      subjectId: data['subjectId'] as String?,
      subjectName: data['subjectName'] as String?,
      periodId: data['periodId'] as String?,
      shiftType: shiftType,
      isEarlyLeave: isEarlyLeave,
      isOvertime: isOvertime,
      source: source,
      deviceId: deviceId,
    );
  }

  Map<String, dynamic> _toMap(
    AttendanceDay day, {
    required String shiftType,
    required bool isNew,
    String? sex,
    int? gradeLevel,
  }) {
    return <String, dynamic>{
      // Keep date as a field for querying (docId is composite).
      'date': day.dateKey,
      if (day.schoolId != null) 'schoolId': day.schoolId,
      'studentUid': day.studentUid,
      if (day.classId != null) 'classId': day.classId,
      if (day.className != null) 'className': day.className,

      //Reporting data
      'gradeLevel': gradeLevel,
      'sex': sex,
      'status': day.status.name,
      'shiftType': shiftType,
      //Timing = nptes
      'clockInAt': day.clockInAt,
      'clockOutAt': day.clockOutAt,
      'lateReason': day.lateReason,
      if (day.takenByUid != null) 'takenByUid': day.takenByUid,
      if (day.subjectId != null) 'subjectId': day.subjectId,
      if (day.subjectName != null) 'subjectName': day.subjectName,
      if (day.periodId != null) 'periodId': day.periodId,
   

      // New boolean flags
      'isEarlyLeave': day.isEarlyLeave,
      'isOvertime': day.isOvertime,

      // Source + deviceId
      'source': day.source.name,
      if (day.deviceId != null) 'deviceId': day.deviceId,
     

     //Location
      if (day.clockInLocation != null)
        'clockInLoc': GeoPoint(
          day.clockInLocation!.lat,
          day.clockInLocation!.lng,
        ),
      if (day.clockOutLocation != null)
        'clockOutLoc': GeoPoint(
          day.clockOutLocation!.lat,
          day.clockOutLocation!.lng,
        ),

      // Audit fields
     
      'updatedAt': FieldValue.serverTimestamp(),
      if (isNew) 'takenAt': FieldValue.serverTimestamp(),
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  AttendanceStatus _statusFromString(String? value) {
    if (value == null || value.isEmpty) {
      return AttendanceStatus.present;
    }
    for (final status in AttendanceStatus.values) {
      if (status.name == value) return status;
    }
    return AttendanceStatus.present;
  }

  /// Parse a stored source string back to [AttendanceSource].
  /// Defaults to [AttendanceSource.studentSelf] for old docs without the field.
  AttendanceSource _sourceFromString(String? value) {
    if (value == null || value.isEmpty) return AttendanceSource.studentSelf;
    for (final source in AttendanceSource.values) {
      if (source.name == value) return source;
    }
    return AttendanceSource.studentSelf;
  }

  AttendanceStatus? _statusFromStringOrNull(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final status in AttendanceStatus.values) {
      if (status.name == value) return status;
    }
    return null;
  }

  String? _normalizeSex(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final upper = trimmed.toUpperCase();
    if (upper == 'M' || upper == 'MALE') return 'M';
    if (upper == 'F' || upper == 'FEMALE') return 'F';
    return null;
  }

  Future<AppUser?> _fetchUserProfile(String studentUid) async {
    final snapshot = await _usersCollection.doc(studentUid).get();
    if (!snapshot.exists) return null;
    return AppUser.fromMap(studentUid, snapshot.data());
  }

  Future<_ResolvedStudentFields> _resolveStudentFields({
    required String studentUid,
    String? sex,
    int? gradeLevel,
  }) async {
    String? resolvedSex = _normalizeSex(sex);
    int? resolvedGradeLevel = gradeLevel;

    if (resolvedSex != null && resolvedGradeLevel != null) {
      return _ResolvedStudentFields(
        sex: resolvedSex,
        gradeLevel: resolvedGradeLevel,
      );
    }

    final profile = await _fetchUserProfile(studentUid);

    resolvedSex ??= _normalizeSex(profile?.sex);
    resolvedGradeLevel ??= profile?.gradeLevelNumber;

    return _ResolvedStudentFields(
      sex: resolvedSex,
      gradeLevel: resolvedGradeLevel,
    );
  }

  String _resolveChangedByUid({
    String? changedByUid,
    String? takenByUid,
    required String studentUid,
  }) {
    final effective = (changedByUid ?? takenByUid ?? studentUid).trim();
    return effective.isEmpty ? studentUid : effective;
  }

  AttendanceLocation? _locationFromDynamic(dynamic value) {
    if (value is GeoPoint) {
      return AttendanceLocation(lat: value.latitude, lng: value.longitude);
    }
    return null;
  }

  /// Stream live updates for a single day's attendance document so that
  /// the UI can react in real time (e.g. admin overrides).
  Stream<AttendanceDay?> fetchDayStream({
    required String schoolId,
    required String studentUid,
    required String dateKey,
    String? shiftType,
  }) {
    final effectiveShiftType = AttendanceDay.normalizeShiftType(shiftType);
    return _dayDoc(
      schoolId: schoolId,
      studentUid: studentUid,
      dateKey: dateKey,
      shiftType: effectiveShiftType,
    ).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _fromDoc(studentUid: studentUid, doc: doc);
    }).handleError((Object error, StackTrace stackTrace) {
      _handleFirestoreError(error, stackTrace);
    });
  }

  // ---------------------------------------------------------------------------
  // Firestore error handling
  // ---------------------------------------------------------------------------

  /// Checks whether [error] is a Firestore "missing composite index" error.
  ///
  /// Firestore throws `failed-precondition` with a message containing
  /// "The query requires an index" and a clickable URL when a composite
  /// index has not been created yet.
  static bool _isMissingIndexError(Object error) {
    if (error is FirebaseException) {
      return error.code == 'failed-precondition' &&
          (error.message?.contains('The query requires an index') ?? false);
    }
    if (error is PlatformException) {
      return error.code == 'failed-precondition' &&
          (error.message?.contains('The query requires an index') ?? false);
    }
    return false;
  }

  /// Wraps a Firestore / platform error into [AttendancePersistenceException].
  ///
  /// Why we detect "The query requires an index":
  /// Firestore composite queries need indexes created in the Firebase console.
  /// When missing, Firestore throws a `failed-precondition` error that includes
  /// a URL to create the index. We log the full error (including that URL) to
  /// the debug console so developers can click the link and create the index,
  /// but we convert it to a friendly [AttendancePersistenceException] so the
  /// app never crashes — the UI just shows an error state.
  ///
  /// For non-index errors we still log and wrap, ensuring raw
  /// FirebaseException / PlatformException never escapes the data layer.
  Never _handleFirestoreError(Object error, StackTrace stackTrace) {
    if (_isMissingIndexError(error)) {
      dev.log(
        'FIRESTORE INDEX NEEDED (attendance)\n'
        'Full error: $error',
        name: 'AttendanceFirestoreSource',
        error: error,
        stackTrace: stackTrace,
      );
      throw AttendancePersistenceException(
        'Attendance query requires a Firestore index',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // Non-index Firestore / platform error
    dev.log(
      'Firestore error (attendance): $error',
      name: 'AttendanceFirestoreSource',
      error: error,
      stackTrace: stackTrace,
    );
    throw AttendancePersistenceException(
      'Attendance data could not be loaded',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}

class _ResolvedStudentFields {
  const _ResolvedStudentFields({required this.sex, required this.gradeLevel});

  final String? sex;
  final int? gradeLevel;
}
