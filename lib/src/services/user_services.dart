import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _userCollection => _firestore.collection('users');

  Future<void> createUser(AppUser user) async {
    try {
      await _userCollection.doc(user.uid).set({
        ...user.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<AppUser?> getUser(String uid) async {
    try {
      DocumentSnapshot snapshot = await _userCollection.doc(uid).get();
      if (snapshot.exists) {
        return AppUser.fromMap(uid, snapshot.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

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

  Future<AppUser?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUser(user.uid);
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _userCollection.doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // 🔴 NEW: listen to Firestore in real-time for this user
  Stream<AppUser?> watchUser(String uid) {
    return _userCollection.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return AppUser.fromSnapshot(
        snapshot as DocumentSnapshot<Map<String, dynamic>>,
      );
    });
  }

}
