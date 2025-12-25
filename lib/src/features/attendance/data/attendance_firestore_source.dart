// lib/src/features/attendance/data/attendance_firestore_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';

/// Low-level Firestore access for attendance.
///
/// - Knows the path: users/{uid}/attendanceDays/{YYYY-MM-DD}
/// - Maps AttendanceDay <-> Firestore document
/// - Does NOT contain UI or business rules (no early/late logic).
class AttendanceFirestoreSource {
  final FirebaseFirestore _db;

  AttendanceFirestoreSource({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  /// users/{uid}/attendanceDays
  CollectionReference<Map<String, dynamic>> _daysCollection(String uid) {
    return _db.collection('users').doc(uid).collection('attendanceDays');
  }

  /// users/{uid}/attendanceDays/{YYYY-MM-DD}
  DocumentReference<Map<String, dynamic>> _dayDoc(String uid, String dateKey) {
    return _daysCollection(uid).doc(dateKey);
  }

  /// Get a single day for a student.
  ///
  /// Returns null if the document does not exist.
  Future<AttendanceDay?> fetchDay({
    required String studentUid,
    required String dateKey,
  }) async {
    final doc = await _dayDoc(studentUid, dateKey).get();
    if (!doc.exists) return null;
    return _fromDoc(studentUid: studentUid, doc: doc);
  }

  /// Convenience wrapper so higher layers can call `getDay` instead of
  /// `fetchDay`. This keeps the repository code a bit more readable.
  Future<AttendanceDay?> getDay({
    required String studentUid,
    required String dateKey,
  }) {
    return fetchDay(studentUid: studentUid, dateKey: dateKey);
  }

  /// Save/overwrite a day for a student.
  ///
  /// - Uses [day.dateKey] as the document ID.
  /// - Caller is responsible for business rules (status, lateReason, etc.).
  Future<void> saveDay({
    required String studentUid,
    required AttendanceDay day,
    bool? isNew,
  }) async {
    // Small safety check: make sure the model's uid matches the Firestore path.
    assert(
      day.studentUid == studentUid,
      'AttendanceDay.studentUid (${day.studentUid}) must match path studentUid ($studentUid)',
    );

    final docRef = _dayDoc(studentUid, day.dateKey);

    // If the caller didn't tell us whether this is a new document, read once
    // to find out. This lets higher layers optionally short‑circuit the extra
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
  /// Dates are normalized to "YYYY-MM-DD" in the same way as [AttendanceDay.dateKeyFor].
  /// Results are ordered descending by date (most recent first).
  Future<List<AttendanceDay>> fetchDaysInRange({
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

    final query = await _daysCollection(studentUid)
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
  Future<List<AttendanceDay>> getRecentDays({
    required String studentUid,
    int limit = 14,
  }) {
    final now = DateTime.now();
    // For "recent N days" we can simply go back (limit - 1) days from today.
    final from = now.subtract(Duration(days: limit - 1));

    return fetchDaysInRange(studentUid: studentUid, from: from, to: now);
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

    return AttendanceDay(
      dateKey: data['date'] as String? ?? doc.id,
      studentUid: studentUid,
      status: status,
      clockInAt: clockInTs?.toDate(),
      clockOutAt: clockOutTs?.toDate(),
      clockInLocation: clockInLoc,
      clockOutLocation: clockOutLoc,
      lateReason: data['lateReason'] as String?,
    );
  }

  Map<String, dynamic> _toMap(AttendanceDay day, {bool isNew = false}) {
    return <String, dynamic>{
      // Keep date both as docId and as a field for querying.
      'date': day.dateKey,
      'studentUid': day.studentUid,
      'status': day.status.name,
      'clockInAt': day.clockInAt,
      'clockOutAt': day.clockOutAt,
      'lateReason': day.lateReason,

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
      'updateAt': FieldValue.serverTimestamp(),
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
    required String studentUid,
    required String dateKey,
  }) {
    return _dayDoc(studentUid, dateKey).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _fromDoc(studentUid: studentUid, doc: doc);
    });
  }
}
