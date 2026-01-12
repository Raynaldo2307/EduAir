// lib/src/features/attendance/domain/attendance_config.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

//import 'attendance_models.dart';

/// Single source of truth for school holidays.
/// Keys must be "YYYY-MM-DD" in the school timezone
/// (same format as AttendanceDay.dateKeyFor).
final schoolHolidayDateKeysProvider = Provider<Set<String>>((ref) {
  return const <String>{
    // 🔹 Example holidays — replace with real Jamaica / your school holidays
    '2025-01-01', // New Year's Day
    '2025-04-18', // Example: Good Friday
    '2025-04-21', // Example: Easter Monday
    '2025-05-23', // Example: Labour Day
    // add more as needed...
  };
});