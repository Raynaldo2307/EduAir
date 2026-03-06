import 'dart:developer' as dev; // 👈 for logging

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:edu_air/src/models/app_user.dart';
import 'package:edu_air/src/services/user_services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // 👇 You can pass scopes here later if you want (e.g. drive, classroom, etc.)
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// ---------------------------
  /// GOOGLE SIGN-IN
  /// ---------------------------
  /// Returns [AppUser] on success, or [null] if the user cancelled.
  /// Only throws on genuine errors (network failure, Firebase config, etc.).
  Future<AppUser?> signInWithGoogle() async {
    dev.log('Starting Google sign-in…', name: 'AuthService');

    // 1. Ask the user to pick a Google account (native iOS screen).
    // Cancel can be a null return OR a PlatformException (code='sign_in_canceled' / '-5').
    // Either way → return null. Never throw for a user-initiated cancel.
    GoogleSignInAccount? googleUser;
    try {
      googleUser = await _googleSignIn.signIn();
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled' || e.code == '-5') {
        dev.log(
          'Google sign-in cancelled by user (code: ${e.code})',
          name: 'AuthService',
        );
        return null; // silent — not an error
      }
      dev.log(
        'Google sign-in PlatformException: code=${e.code}',
        name: 'AuthService',
        error: e,
      );
      throw Exception('Google sign-in failed. Please try again.');
    }

    if (googleUser == null) {
      dev.log('Google sign-in returned null (user backed out)', name: 'AuthService');
      return null; // silent — not an error
    }

    try {
      // 2. Get Google auth tokens.
      final googleAuth = await googleUser.authentication;
      dev.log(
        'Got Google tokens (idToken=${googleAuth.idToken != null})',
        name: 'AuthService',
      );

      // 3. Turn Google tokens into Firebase credential.
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with that Google credential.
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      dev.log(
        'Firebase user from Google: ${firebaseUser.uid}',
        name: 'AuthService',
      );

      // 5. Try to load Firestore profile.
      AppUser? appUser = await _userService.getUser(firebaseUser.uid);

      // 6. If first time, create profile.
      if (appUser == null) {
        dev.log(
          'No Firestore profile found, creating new one…',
          name: 'AuthService',
        );

        final parts = (googleUser.displayName ?? '').trim().split(
          RegExp(r'\s+'),
        );
        final firstName = parts.isNotEmpty ? parts.first : '';
        final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

        appUser = AppUser(
          uid: firebaseUser.uid,
          firstName: firstName,
          lastName: lastName,
          email: firebaseUser.email ?? '',
          phone: firebaseUser.phoneNumber ?? '',
          role:
              'student', // 👈 for now, default. Later we can set '' and send to /selectRole.
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _userService.createUser(appUser);

        dev.log(
          'New Firestore user created for ${appUser.uid}',
          name: 'AuthService',
        );
      } else {
        dev.log(
          'Existing Firestore user loaded: ${appUser.uid}',
          name: 'AuthService',
        );
      }

      return appUser;
    } on FirebaseAuthException catch (e, st) {
      dev.log(
        'FirebaseAuthException during Google sign in: ${e.code} ${e.message}',
        name: 'AuthService',
        stackTrace: st,
        error: e,
      );
      throw Exception('Google sign-in failed (auth): ${e.message ?? e.code}');
    } catch (e, st) {
      dev.log(
        'Unknown error during Google sign in: $e',
        name: 'AuthService',
        stackTrace: st,
        error: e,
      );
      throw Exception('Google sign-in failed: $e');
    }
  }

  /// ---------------------------
  /// SIGN OUT
  /// ---------------------------
  Future<void> signOut() async {
    dev.log('Signing out…', name: 'AuthService');
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  /// ---------------------------
  /// CURRENT USER / STREAM
  /// ---------------------------
  Future<User?> getCurrentFirebaseUser() async {
    return _auth.currentUser;
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  /// ---------------------------
  /// ACCOUNT MANAGEMENT
  /// ---------------------------
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      throw Exception('Delete account failed: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      dev.log('Sending password reset email to $email', name: 'AuthService');
      await _auth.sendPasswordResetEmail(email: email);
      dev.log('Password reset email sent to $email', name: 'AuthService');
    } on FirebaseAuthException catch (e, st) {
      dev.log(
        'FirebaseAuthException on resetPassword: ${e.code} ${e.message}',
        name: 'AuthService',
        stackTrace: st,
        error: e,
      );
      //Mpap Firebase error codes + friendly messages

      switch (e.code) {
        case 'invalid email':
          throw Exception('That email addres looks invaild.');
        case 'user not found':
          throw Exception('No account found wiht that email.');
        default:
          throw Exception('Colud not send reset email.Please try again.');
      }
    } catch (e, st) {
      dev.log(
        'Unknown error on. resetPasword: $e',
        name: 'AuthService',
        stackTrace: st,
        error: e,
      );
      throw Exception('Could no send rese email. Please try again');
    }
  }
}
