// lib/src/features/attendance/application/attendance_error_mapper.dart

import 'package:edu_air/src/features/attendance/domain/attendance_exceptions.dart';

/// Maps attendance domain exceptions to user-friendly messages.
///
/// Usage in controllers:
/// ```dart
/// try {
///   await service.clockIn(...);
/// } catch (e) {
///   final message = mapAttendanceErrorToMessage(e);
///   // Show message in UI (SnackBar, Dialog, etc.)
/// }
/// ```
///
/// The UI layer should catch these and display the returned strings.
/// This keeps error messages consistent across the app.
String mapAttendanceErrorToMessage(Object error) {
  if (error is NotSchoolDayException) {
    return 'School is not in session today (weekend or holiday).';
  }

  if (error is AlreadyClockedInException) {
    return 'You already clocked in for this shift.';
  }

  if (error is AlreadyClockedOutException) {
    return 'You already clocked out for this shift.';
  }

  if (error is NoClockInFoundException) {
    return 'You need to clock in before you can clock out.';
  }

  if (error is LateReasonRequiredException) {
    return 'Please choose a reason for being late.';
  }

  if (error is InvalidLateReasonException) {
    return 'That late reason is not recognized. Please select one from the list.';
  }

  // AttendancePersistenceException: covers Firestore errors wrapped by the data layer.
  // We check for the "missing index" case specifically so users get a calm message,
  // while the full Firestore error + index-creation URL is already in the debug
  // console (logged by AttendanceFirestoreSource before throwing).
  if (error is AttendancePersistenceException) {
    final msg = error.message;
    final causeStr = error.cause?.toString() ?? '';

    // Missing Firestore composite index — transient from the dev's perspective.
    if (msg.contains('requires a Firestore index') ||
        causeStr.contains('failed-precondition')) {
      return 'We couldn\'t load your attendance right now. Please try again in a moment.';
    }

    // Any other persistence / network error.
    return 'Something went wrong while loading attendance. Please try again.';
  }

  // Generic fallback for unexpected errors
  return 'Something went wrong while recording your attendance. Please try again.';
}

/// Extension method for convenient error mapping on exceptions.
extension AttendanceErrorMapping on Object {
  String toAttendanceMessage() => mapAttendanceErrorToMessage(this);
}
