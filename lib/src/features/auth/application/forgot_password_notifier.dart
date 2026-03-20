import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class ForgotPasswordState {
  final bool isLoading;
  final String? errorMessage;
  final int step;      // 1 = enter email,  2 = enter code + new password
  final String? email; // carried from step 1 → step 2

  const ForgotPasswordState({
    this.isLoading   = false,
    this.errorMessage,
    this.step        = 1,
    this.email,
  });

  ForgotPasswordState copyWith({
    bool?   isLoading,
    String? errorMessage,
    int?    step,
    String? email,
  }) =>
      ForgotPasswordState(
        isLoading:    isLoading    ?? this.isLoading,
        errorMessage: errorMessage, // null clears the error
        step:         step         ?? this.step,
        email:        email        ?? this.email,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  final Ref _ref;

  ForgotPasswordNotifier(this._ref) : super(const ForgotPasswordState());

  /// Step 1 — sends the 6-digit code to the user's email.
  /// On success, advances to step 2 and remembers the email.
  Future<void> sendCode(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(authApiRepositoryProvider);
      await repo.forgotPassword(email: email);
      state = state.copyWith(isLoading: false, step: 2, email: email);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Step 2 — verifies the code and sets the new password.
  /// Returns true on success so the UI can navigate to login.
  Future<bool> resetPassword(String code, String newPassword) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(authApiRepositoryProvider);
      await repo.resetPassword(
        email:       state.email!,
        code:        code,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid or expired code. Please try again.',
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);

  // User taps "Didn't get the code?" — go back to email entry
  void backToStep1() => state = const ForgotPasswordState();
}

// ─── Provider ─────────────────────────────────────────────────────────────────

// autoDispose — disposes when the user leaves the forgot-password flow.
// A fresh notifier (step = 1) is created each time they return.
final forgotPasswordNotifierProvider =
    StateNotifierProvider.autoDispose<ForgotPasswordNotifier, ForgotPasswordState>(
  (ref) => ForgotPasswordNotifier(ref),
);
