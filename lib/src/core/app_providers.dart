import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/models/app_user.dart';
import 'package:edu_air/src/features/auth/services/auth_services.dart';
import 'package:edu_air/src/services/user_services.dart';

/// Global provider holding the currently authenticated [AppUser].
final userProvider = StateProvider<AppUser?>((ref) => null);

/// Exposes a singleton [AuthService] instance through Riverpod.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Helper provider to access [UserService] wherever needed.
final userServiceProvider = Provider<UserService>((ref) => UserService());

/// Decides which route to show after the splash.
///
/// Responsibilities:
/// - Check if there is a logged-in Firebase user.
/// - If there is, load their profile from Firestore.
/// - Update [userProvider] with the loaded profile.
/// - Return the correct route name based on the user's role.
final startupRouteProvider = FutureProvider<String>((ref) async {
  final authService = ref.read(authServiceProvider);
  final userService = ref.read(userServiceProvider);
  final userNotifier = ref.read(userProvider.notifier);

  // Default route if not logged in.
  var targetRoute = '/onboarding';

  // Step 1: Check if there is a logged-in Firebase user.
  final firebaseUser = await authService.getCurrentFirebaseUser();

  if (firebaseUser != null) {
    // Step 2: Load profile from Firestore.
    final profile = await userService.getUser(firebaseUser.uid);

    if (profile != null) {
      // Step 3: Update global user state.
      userNotifier.state = profile;

      // Step 4: Decide route based on role.
      final role = profile.role ; // adjust if non-nullable

      if (role.isEmpty) {
        targetRoute = '/selectRole';
      } else if (role == 'student') {
        targetRoute = '/studentHome';
      } else if (role == 'teacher') {
        targetRoute = '/teacherHome';
      } else {
        targetRoute = '/home'; // fallback
      }
    }
  }

  return targetRoute;
});
