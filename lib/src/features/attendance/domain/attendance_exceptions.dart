// lib/src/features/attendance/domain/attendance_exceptions.dart

library;

/// Custom exceptions for attendance business logic.
///
/// These exceptions are thrown by [AttendanceService] and caught by the UI layer
/// (Riverpod controllers) to display user-friendly error messages.
///
/// Design:
/// - Each exception extends [Exception] and carries a message.
/// - UI can pattern-match on exception type for localized/friendly messages.
/// - Keep exceptions pure domain concepts (no Firestore or UI types).

/// Base class for all attendance domain exceptions.
abstract class AttendanceException implements Exception {
  final String message;
  const AttendanceException(this.message);

  @override
  String toString() => 'AttendanceException: $message';
}

/// Thrown when trying to clock in/out on a weekend or school holiday.
class NotSchoolDayException extends AttendanceException {
  const NotSchoolDayException([String? message])
      : super(message ?? 'Cannot clock in/out: not a school day (weekend or holiday).');
}

/// Thrown when student tries to clock in again after already clocking in for this shift/day.
class AlreadyClockedInException extends AttendanceException {
  const AlreadyClockedInException([String? message])
      : super(message ?? 'Already clocked in for this shift today.');
}

/// Thrown when student tries to clock out again after already clocking out.
class AlreadyClockedOutException extends AttendanceException {
  const AlreadyClockedOutException([String? message])
      : super(message ?? 'Already clocked out for this shift today.');
}

/// Thrown when student clocks out without having clocked in first.
class NoClockInFoundException extends AttendanceException {
  const NoClockInFoundException([String? message])
      : super(message ?? 'Cannot clock out: no clock-in found for this shift/day.');
}

/// Thrown when student is late and doesn't provide a late reason.
///
/// MoEYI compliance: Late reason is required for Form SF4 reporting
/// and behavioral analysis under the Jamaican Data Protection Act 2020.
class LateReasonRequiredException extends AttendanceException {
  const LateReasonRequiredException([String? message])
      : super(message ?? 'Late clock-in requires a valid reason (MoEYI compliance).');
}

/// Thrown when the provided late reason is not a valid MoEYI category.
class InvalidLateReasonException extends AttendanceException {
  final String providedReason;

  const InvalidLateReasonException(this.providedReason, [String? message])
      : super(message ??
            'Invalid late reason: "$providedReason". Must use a standard MoEYI category.');
}

/// Thrown when Firestore or repository operations fail unexpectedly.
///
/// This wraps lower-level errors (network issues, permission denied, etc.)
/// so the service layer stays free of Firestore types.
class AttendancePersistenceException extends AttendanceException {
  final Object? cause;
  final StackTrace? stackTrace;

  const AttendancePersistenceException(
    super.message, {
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() {
    final base = 'AttendancePersistenceException: $message';
    if (cause != null) {
      return '$base\nCaused by: $cause';
    }
    return base;
  }
}
