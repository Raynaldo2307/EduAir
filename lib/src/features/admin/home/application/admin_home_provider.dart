import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/models/app_user.dart';
import 'package:edu_air/src/features/admin/students/application/admin_students_provider.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class AdminHomeData {
  final int totalStudents;
  final int presentToday;
  final int absentToday;
  final List<AppUser> recentStudents;
  final String schoolName;

  const AdminHomeData({
    required this.totalStudents,
    required this.presentToday,
    required this.absentToday,
    required this.recentStudents,
    required this.schoolName,
  });
}

// ─── Provider ─────────────────────────────────────────────────────────────────

/// Aggregates data for the admin home dashboard.
/// - totalStudents: from the full alphabetical list (schoolStudentsProvider)
/// - recentStudents: separate call for 3 newest enrollments (order=newest&limit=3)
/// autoDispose — refreshes each time admin navigates to the home tab.
final adminHomeProvider = FutureProvider.autoDispose<AdminHomeData>((ref) async {
  final repo     = ref.read(studentsApiRepositoryProvider);
  final client   = ref.read(apiClientProvider);
  final user     = ref.read(userProvider);
  final schoolId = user?.schoolId ?? '';

  final allStudents  = await ref.watch(schoolStudentsProvider.future);
  final recentRaw    = await repo.getAll(order: 'newest', limit: 3);
  final schoolResp   = await client.dio.get('/api/schools/$schoolId');

  // Fetch today's attendance counts — GET /api/attendance/stats (no date = today)
  // present = early + present, absent = absent only
  final statsResp  = await client.dio.get('/api/attendance/stats');
  final statsData  = statsResp.data?['data'] as Map<String, dynamic>? ?? {};
  final present    = (statsData['present'] as num?)?.toInt() ?? 0;
  final absent     = (statsData['absent']  as num?)?.toInt() ?? 0;

  final recentStudents = recentRaw.map(nodeStudentToAppUser).toList();
  final schoolName     = (schoolResp.data?['data']?['name'] as String?) ?? 'EduAir School';

  return AdminHomeData(
    totalStudents:  allStudents.length,
    presentToday:   present,
    absentToday:    absent,
    recentStudents: recentStudents,
    schoolName:     schoolName,
  );
});
