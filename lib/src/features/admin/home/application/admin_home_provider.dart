import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/models/app_user.dart';
import 'package:edu_air/src/features/admin/students/application/admin_students_provider.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class AdminHomeData {
  final int totalStudents;
  final int presentToday;
  final int absentToday;
  final int totalTeachers;
  final int lateToday;
  final List<AppUser> recentStudents;
  final String schoolName;

  const AdminHomeData({
    required this.totalStudents,
    required this.presentToday,
    required this.absentToday,
    required this.recentStudents,
    required this.schoolName,
    required this.totalTeachers,
    required this.lateToday
  });
}

// ─── Provider ─────────────────────────────────────────────────────────────────

/// Aggregates data for the admin home dashboard.
/// - stats: single call to GET /api/dashboard/ (totalStudents, present, absent, late, teachers)
/// - recentStudents: 3 newest enrollments
/// autoDispose — refreshes each time admin navigates to the home tab.
final adminHomeProvider = FutureProvider.autoDispose<AdminHomeData>((ref) async {
  final repo     = ref.read(studentsApiRepositoryProvider);
  final client   = ref.read(apiClientProvider);
  final user     = ref.read(userProvider);
  final schoolId = user?.schoolId ?? '';

  final recentRaw  = await repo.getAll(order: 'newest', limit: 3);
  final schoolResp = await client.dio.get('/api/schools/$schoolId');

  // One call returns all 5 stats — avoids loading the full student list just to count it.
  final dashResp   = await client.dio.get('/api/dashboard/');

  // No 'data' wrapper on this endpoint — fields are at the top level of the response.
  final dashData      = dashResp.data as Map<String, dynamic>? ?? {};
  final present       = (dashData['dailyAttendance'] as num?)?.toInt() ?? 0; // present + late
  final absentToday   = (dashData['absentToday']     as num?)?.toInt() ?? 0;
  final totalStudents = (dashData['totalStudents']   as num?)?.toInt() ?? 0;
  final totalTeachers = (dashData['totalTeachers']   as num?)?.toInt() ?? 0;
  final lateToday     = (dashData['lateToday']       as num?)?.toInt() ?? 0;

  final recentStudents = recentRaw.map(nodeStudentToAppUser).toList();
  final schoolName     = (schoolResp.data?['data']?['name'] as String?) ?? 'EduAir School';

  return AdminHomeData(
    totalStudents:  totalStudents,
    presentToday:   present,
    absentToday:    absentToday,
    totalTeachers:  totalTeachers,
    lateToday:      lateToday,
    recentStudents: recentStudents,
    schoolName:     schoolName,
  );
});
