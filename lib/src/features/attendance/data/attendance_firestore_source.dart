// lib/src/features/attendance/data/attendance_firestore_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';

/// Low-level Firestore access for attendance.
///
/// - Knows the path: schools/{schoolId}/attendance/{YYYY-MM-DD}_{studentUid}
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

  /// Document ID: "{dateKey}_{studentUid}"
  String _docIdFor(String dateKey, String studentUid) {
    return '${dateKey}_$studentUid';
  }

  /// Recover the dateKey ("YYYY-MM-DD") from a composite docId.
  String _dateKeyFromDocId(String docId) {
    final separatorIndex = docId.indexOf('_');
    if (separatorIndex == -1) return docId;
    return docId.substring(0, separatorIndex);
  }

  /// schools/{schoolId}/attendance/{YYYY-MM-DD}_{studentUid}
  DocumentReference<Map<String, dynamic>> _dayDoc({
    required String schoolId,
    required String studentUid,
    required String dateKey,
  }) {
    return _daysCollection(schoolId).doc(_docIdFor(dateKey, studentUid));
  }

  /// Get a single day for a student.
  ///
  /// Returns null if the document does not exist.
  Future<AttendanceDay?> fetchDay({
    required String schoolId,
    required String studentUid,
    required String dateKey,
  }) async {
    final doc = await _dayDoc(
      schoolId: schoolId,
      studentUid: studentUid,
      dateKey: dateKey,
    ).get();

    if (!doc.exists) return null;
    return _fromDoc(studentUid: studentUid, doc: doc);
  }

  /// Convenience wrapper so higher layers can call `getDay` instead of
  /// `fetchDay`. This keeps the repository code a bit more readable.
  Future<AttendanceDay?> getDay({
    required String schoolId,
    required String studentUid,
    required String dateKey,
  }) {
    return fetchDay(
      schoolId: schoolId,
      studentUid: studentUid,
      dateKey: dateKey,
    );
  }

  /// Save/overwrite a day for a student.
  ///
  /// - Uses [day.dateKey] + studentUid as the document ID.
  /// - Caller is responsible for business rules (status, lateReason, etc.).
  Future<void> saveDay({
    required String schoolId,
    required String studentUid,
    required AttendanceDay day,
    bool? isNew,
  }) async {
    // Small safety check: make sure the model's uid matches the Firestore path.
    assert(
      day.studentUid == studentUid,
      'AttendanceDay.studentUid (${day.studentUid}) must match path studentUid ($studentUid)',
    );

    final docRef = _dayDoc(
      schoolId: schoolId,
      studentUid: studentUid,
      dateKey: day.dateKey,
    );

    // If the caller didn't tell us whether this is a new document, read once
    // to find out. This lets higher layers optionally short-circuit the extra
    // read when they already know it's new vs existing.
    bool effectiveIsNew;
    if (isNew != null) {
      effectiveIsNew = isNew;
    } else {
      final snapshot = await docRef.get();
      effectiveIsNew = !snapshot.exists;
    }

    await docRef.set(
      _toMap(day, isNew: effectiveIsNew),
      SetOptions(merge: true),
    );
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
  ///   - fields: studentUid (==), date (range/orderBy)
  Future<List<AttendanceDay>> fetchDaysInRange({
    required String schoolId,
    required String studentUid,
    required DateTime from,
    required DateTime to,
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

    final query = await _daysCollection(schoolId)
        .where('studentUid', isEqualTo: studentUid)
        .where('date', isGreaterThanOrEqualTo: fromKey)
        .where('date', isLessThanOrEqualTo: toKey)
        .orderBy('date', descending: true)
        .get();

    return query.docs
        .map((doc) => _fromDoc(studentUid: studentUid, doc: doc))
        .toList();
  }

  /// Convenience helper: fetch the most recent [limit] days for a student,
  /// ordered by date descending (today first).
  ///
  /// NOTE: This uses DateTime.now(). If you later standardize on
  /// AttendanceService.schoolNow() for timezone correctness, you can move
  /// the "what is today?" logic up to the service and call [fetchDaysInRange].
  Future<List<AttendanceDay>> getRecentDays({
    required String schoolId,
    required String studentUid,
    int limit = 14,
  }) {
    final now = DateTime.now();
    // For "recent N days" we can simply go back (limit - 1) days from today.
    final from = now.subtract(Duration(days: limit - 1));

    return fetchDaysInRange(
      schoolId: schoolId,
      studentUid: studentUid,
      from: from,
      to: now,
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

    final statusStr = data['status'] as String?;
    final status = AttendanceStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => AttendanceStatus.present, // safe fallback
    );

    final clockInTs = data['clockInAt'] as Timestamp?;
    final clockOutTs = data['clockOutAt'] as Timestamp?;

    final clockInLoc = _locationFromDynamic(data['clockInLoc']);
    final clockOutLoc = _locationFromDynamic(data['clockOutLoc']);

    // NEW (with safe default to false if field is missing)
    final isEarlyLeave = (data['isEarlyLeave'] as bool?) ?? false;
    final isOvertime = (data['isOvertime'] as bool?) ?? false;

    return AttendanceDay(
      dateKey: data['date'] as String? ?? _dateKeyFromDocId(doc.id),
      studentUid: studentUid,
      status: status,
      clockInAt: clockInTs?.toDate(),
      clockOutAt: clockOutTs?.toDate(),
      clockInLocation: clockInLoc,
      clockOutLocation: clockOutLoc,
      lateReason: data['lateReason'] as String?,
      isEarlyLeave: isEarlyLeave,
      isOvertime: isOvertime,
    );
  }

  Map<String, dynamic> _toMap(AttendanceDay day, {bool isNew = false}) {
    return <String, dynamic>{
      // Keep date as a field for querying (docId is composite).
      'date': day.dateKey,
      'studentUid': day.studentUid,
      'status': day.status.name,
      'clockInAt': day.clockInAt,
      'clockOutAt': day.clockOutAt,
      'lateReason': day.lateReason,

      // New boolean flags
      'isEarlyLeave': day.isEarlyLeave,
      'isOvertime': day.isOvertime,

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
      'updateAt': FieldValue.serverTimestamp(), // (typo kept for compat)
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  AttendanceLocation? _locationFromDynamic(dynamic value) {
    if (value is GeoPoint) {
      return AttendanceLocation(lat: value.latitude, lng: value.longitude);
    }
    return null;
  }

  /// Stream live updates for a single day's attendance document so that
  /// the UI can react in real time (e.g. admin overrides).
  Stream<AttendanceDay?> watchDay({
    required String schoolId,
    required String studentUid,
    required String dateKey,
  }) {
    return _dayDoc(
      schoolId: schoolId,
      studentUid: studentUid,
      dateKey: dateKey,
    ).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _fromDoc(studentUid: studentUid, doc: doc);
    });
  }
}
