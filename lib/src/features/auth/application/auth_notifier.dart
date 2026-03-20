import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_error_handler.dart';
import 'package:edu_air/src/models/app_user.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class AuthState {
  final bool isLoading;
  final String? errorMessage;

  const AuthState({this.isLoading = false, this.errorMessage});

  AuthState copyWith({bool? isLoading, String? errorMessage}) => AuthState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage, // null clears the error
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState());

  // Determines the home screen for the logged-in role.
  // Mirrors the same logic in startupRouteProvider.
  String _routeForRole(String role, String? schoolId) {
    if (role.isEmpty) return '/selectRole';
    if (schoolId == null || schoolId.isEmpty) return '/noSchool';
    if (role == 'student') return '/studentHome';
    if (role == 'teacher' || role == 'admin' || role == 'principal') {
      return '/teacherHome';
    }
    return '/onboarding';
  }

  /// Calls the Node API login endpoint, builds the AppUser,
  /// sets the global userProvider, and returns the target route.
  /// Returns null on failure — error message is set in state.
  Future<String?> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repo = _ref.read(authApiRepositoryProvider);
      final data = await repo.login(email: email, password: password);
      final userData = data['user'] as Map<String, dynamic>;

      final role     = userData['role']?.toString()    ?? '';
      final schoolId = userData['schoolId']?.toString();

      _ref.read(userProvider.notifier).state = AppUser(
        uid:               userData['id'].toString(),
        firstName:         userData['firstName']        ?? '',
        lastName:          userData['lastName']         ?? '',
        email:             userData['email']            ?? '',
        phone:             '',
        role:              role,
        schoolId:          schoolId,
        defaultShiftType:  userData['defaultShiftType']  as String?,
        isShiftSchool:     userData['isShiftSchool']     as bool? ?? false,
        studentId:         userData['studentId']         as String?,
        currentShift:      userData['currentShift']      as String?,
        sex:               userData['sex']               as String?,
        classId:           userData['classId']           as String?,
        className:         userData['className']         as String?,
        gradeLevel:        userData['gradeLevel']        as String?,
        homeroomClassId:   userData['homeroomClassId']   as String?,
        homeroomClassName: userData['homeroomClassName'] as String?,
      );

      state = state.copyWith(isLoading: false);
      return _routeForRole(role, schoolId);
    } catch (e, st) {
      final message = AppErrorHandler.message(e, context: 'SignIn', stackTrace: st);
      state = state.copyWith(isLoading: false, errorMessage: message);
      return null;
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);
