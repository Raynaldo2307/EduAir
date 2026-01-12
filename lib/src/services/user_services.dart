import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Root collection for all identities
  CollectionReference<Map<String, dynamic>> get _userCollection =>
      _firestore.collection('users');

  /// 1. Create User with Multi-Tenant Defaults
  Future<void> createUser(AppUser user) async {
    try {
      await _userCollection.doc(user.uid).set({
        ...user.toMap(),
        // Ensure every user starts with at least a role
        'role': user.role.isEmpty ? 'student' : user.role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Multi-tenant Setup Failed: $e');
    }
  }

  /// 2. Fetch Identity
  Future<AppUser?> getUser(String uid) async {
    try {
      final snapshot = await _userCollection.doc(uid).get();
      if (!snapshot.exists) return null;
      return AppUser.fromMap(uid, snapshot.data()!);
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  /// 3. Secure Update (Respects Role/School constraints)
  Future<void> updateUser(AppUser user) async {
    try {
      await _userCollection.doc(user.uid).update({
        ...user.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// ✅ Used by SelectRolePage to store the chosen role (student/teacher)
  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _userCollection.doc(uid).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// 4. Attach User to School (CRITICAL for SelectSchoolPage)
  /// This is the "Floor 1" link that locks a student to a building.
  Future<void> updateUserSchoolId({
    required String uid,
    required String schoolId,
  }) async {
    try {
      await _userCollection.doc(uid).update({
        'schoolId': schoolId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to link school: $e');
    }
  }

  // ───────── MULTI-TENANT QUERY METHODS (NEW) ─────────

  /// 5. Get all Students for a specific School
  /// Used by Teachers/Principals to see their campus list.
  Future<List<AppUser>> getStudentsBySchool(String schoolId) async {
    final snap = await _userCollection
        .where('schoolId', isEqualTo: schoolId)
        .where('role', isEqualTo: 'student')
        .get();

    return snap.docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).toList();
  }

  /// 6. Get all Staff/Teachers for a specific School
  /// Used by Principals to manage their team.
  Future<List<AppUser>> getStaffBySchool(String schoolId) async {
    final snap = await _userCollection
        .where('schoolId', isEqualTo: schoolId)
        .where('role', whereIn: ['teacher', 'principal', 'staff'])
        .get();

    return snap.docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).toList();
  }

  // ───────── AUTH HELPERS ─────────

  Future<AppUser?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUser(user.uid);
  }

  Stream<AppUser?> watchUser(String uid) {
    return _userCollection.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return AppUser.fromMap(snapshot.id, snapshot.data()!);
    });
  }
}
