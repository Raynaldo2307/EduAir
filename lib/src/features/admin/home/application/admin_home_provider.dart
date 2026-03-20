import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/models/app_user.dart';
import 'package:edu_air/src/features/admin/students/application/admin_students_provider.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class AdminHomeData {
  final int totalStudents;
  final List<AppUser> recentStudents;

  const AdminHomeData({
    required this.totalStudents,
    required this.recentStudents,
  });
}

// ─── Provider ─────────────────────────────────────────────────────────────────

/// Aggregates data for the admin home dashboard.
/// Reuses schoolStudentsProvider — no duplicate API call.
/// autoDispose — refreshes each time admin navigates to the home tab.
final adminHomeProvider = FutureProvider.autoDispose<AdminHomeData>((ref) async {
  // Watch so home refreshes automatically when students list changes
  final students = await ref.watch(schoolStudentsProvider.future);

  return AdminHomeData(
    totalStudents:  students.length,
    recentStudents: students.take(3).toList(),
  );
});
