import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
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
/// - totalStudents: from the full alphabetical list (schoolStudentsProvider)
/// - recentStudents: separate call for 3 newest enrollments (order=newest&limit=3)
/// autoDispose — refreshes each time admin navigates to the home tab.
final adminHomeProvider = FutureProvider.autoDispose<AdminHomeData>((ref) async {
  final repo = ref.read(studentsApiRepositoryProvider);

  // Two parallel calls — total count (full list) + 3 newest
  final results = await Future.wait([
    ref.watch(schoolStudentsProvider.future),
    repo.getAll(order: 'newest', limit: 3),
  ]);

  final allStudents    = results[0] as List<AppUser>;
  final recentRaw      = results[1] as List<Map<String, dynamic>>;
  final recentStudents = recentRaw.map(nodeStudentToAppUser).toList();

  return AdminHomeData(
    totalStudents:  allStudents.length,
    recentStudents: recentStudents,
  );
});
