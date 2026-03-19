// lib/src/core/app_error_handler.dart
//
// Centralized API / network error handler.
//
// Use this wherever a Dio call can fail — sign in, attendance, admin pages, etc.
// It logs every error to the debug console and returns a clean user-facing message.
//
// Usage:
//   } catch (e, st) {
//     final message = AppErrorHandler.message(e);
//     // show message in UI
//   }

import 'dart:developer' as dev;
import 'dart:io';
import 'package:dio/dio.dart';

class AppErrorHandler {
  AppErrorHandler._();

  /// Returns a user-friendly error message AND logs the raw error to the
  /// debug console so you can always see what went wrong during testing.
  static String message(Object error, {String context = 'App', StackTrace? stackTrace}) {
    dev.log(
      '[ERROR] $context: ${error.runtimeType} — $error',
      name: 'AppErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );

    if (error is DioException) {
      return _handleDio(error);
    }

    if (error is SocketException) {
      return 'No internet connection. Please turn on Wi-Fi or mobile data and try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  static String _handleDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        // Check if the underlying cause is a missing network
        final cause = e.error;
        if (cause is SocketException) {
          return 'No internet connection. Please turn on Wi-Fi or mobile data and try again.';
        }
        return 'Cannot reach the server. Please check your connection and try again.';

      default:
        final status = e.response?.statusCode;
        final serverMsg = e.response?.data is Map
            ? e.response?.data['message'] as String?
            : null;

        if (serverMsg != null && serverMsg.isNotEmpty) return serverMsg;
        if (status == 401) return 'Invalid email or password. Please try again.';
        if (status == 403) return 'You do not have permission to do that.';
        if (status == 404) return 'The requested record was not found.';
        if (status == 409) return 'This action conflicts with an existing record.';
        if (status != null && status >= 500) {
          return 'The server ran into a problem. Please try again in a moment.';
        }
        return 'Something went wrong. Please try again.';
    }
  }
}
