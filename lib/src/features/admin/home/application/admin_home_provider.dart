import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/models/app_user.dart';
import 'package:edu_air/src/features/admin/students/application/admin_students_provider.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

// Represents one day of attendance data returned by GET /api/dashboard/trends.
// Each row from the backend has a date and three counts: present, late, absent.
class AttendanceTrendPoint {
  final String date;         // 'YYYY-MM-DD' — the attendance date
  final int presentCount;    // students marked 'present' that day
  final int lateCount;       // students marked 'late' that day
  final int absentCount;     // students marked 'absent' that day

  const AttendanceTrendPoint({
    required this.date,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
  });

  // Everyone who physically showed up = present + late.
  // This is what the trend chart plots on the y-axis.
  // It's a getter, not a stored field, because it's derived — never store what you can compute.
  int get totalPresent => presentCount + lateCount;
}
class TopAbsentStudent{
  final String firstName;
  final String lastName;
  final String className;
  final double absencePercent;
  final String? photoUrl;

  const TopAbsentStudent({
    required this.firstName,
    required this.lastName,
    required this.className,
    required this.absencePercent,
     this.photoUrl,
  });

  String get initials {
    String a = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    String b = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return (a + b).isNotEmpty ? (a + b) : 'U';
  }




}



class StaffConsistency {
  final String firstName;
  final String lastName;
  final String department;
  final String? photoUrl;

  const StaffConsistency({
    required this.firstName,
    required this.lastName,
    required this.department,
    this.photoUrl,
  });

  String get initials {
    String a = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    String b = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return (a + b).isNotEmpty ? (a + b) : 'U';
  }
}

// The single data object that powers the entire admin home dashboard.
// One provider fetch fills all of this — stats, trend, school name, recent students.
class AdminHomeData {
  final int totalStudents;                      // active enrolled students
  final int presentToday;                       // clocked in today (present + late combined)
  final int absentToday;                        // absent today
  final int totalTeachers;                      // active teachers in this school
  final int lateToday;                          // arrived after grace period today
  final List<AppUser> recentStudents;           // 3 newest enrollments for the dashboard list
  final String schoolName;                      // displayed in the header
  final List<AttendanceTrendPoint> trendData;   // last 30 days, one point per day
  final String trendLabel;
  const AdminHomeData({
    required this.totalStudents,
    required this.presentToday,
    required this.absentToday,
    required this.recentStudents,
    required this.schoolName,
    required this.totalTeachers,
    required this.lateToday,
    required this.trendData,
    required this.trendLabel,
  });
}

// Compares this week's attendance total vs last week's and returns a human-readable label.
// Called once after trendData is parsed — result is stored on AdminHomeData.trendLabel.
String _buildTrendLabel(List<AttendanceTrendPoint> trend) {
  // Need at least 14 days to compare two full weeks. If the school is new, say so clearly.
  if (trend.length < 14) return 'Not enough data for comparison';

  // The API returns data sorted oldest → newest (ORDER BY attendance_date ASC).
  // last7  = the 7 most recent days  (this week)
  // prior7 = the 7 days before that  (last week)
  final last7  = trend.sublist(trend.length - 7);
  final prior7 = trend.sublist(trend.length - 14, trend.length - 7);

  // fold() collapses a list into a single value.
  // Start at 0, then for each point add totalPresent to the running sum.
  // Result: total students who showed up across the 7-day window.
  final last7Total  = last7.fold<int>(0,  (sum, p) => sum + p.totalPresent);
  final prior7Total = prior7.fold<int>(0, (sum, p) => sum + p.totalPresent);

  // Guard: if nobody attended last week (e.g. holiday week), division by zero would crash.
  if (prior7Total == 0) return 'No comparison data';

  // Percentage change formula: ((new - old) / old) * 100
  final delta = (last7Total - prior7Total) / prior7Total * 100;

  // Show '+' explicitly for positive delta — without it, '+3.2%' would just show '3.2%'
  final sign = delta >= 0 ? '+' : '';
  // Human-readable direction word for the label e.g. "increase" or "decrease"
  final dir  = delta >= 0 ? 'increase' : 'decrease';

  // toStringAsFixed(1) rounds to 1 decimal place → "3.2" not "3.2000000000001"
  return '$sign${delta.toStringAsFixed(1)}% $dir from last week';
}

// ─── Provider ─────────────────────────────────────────────────────────────────

// autoDispose means the provider is destroyed when the admin leaves the home tab
// and rebuilt fresh when they return — so stats are never stale from a previous visit.
final adminHomeProvider = FutureProvider.autoDispose<AdminHomeData>((ref) async {
  // ref.read (not ref.watch) — we only need the value once, not a live stream.
  final repo     = ref.read(studentsApiRepositoryProvider);
  final client   = ref.read(apiClientProvider);
  final user     = ref.read(userProvider);

  // school_id comes from the JWT via userProvider — the client never sends it manually.
  // This is multi-tenancy: every query is scoped to this school automatically.
  final schoolId = user?.schoolId ?? '';

  // Fetch the 3 most recently enrolled students for the "Recent Students" list.
  final recentRaw = await repo.getAll(order: 'newest', limit: 3);

  // Fire all three API calls at the same time using Future.wait.
  // Without this, each call would wait for the previous to finish — 3x slower.
  // Since none of these calls depend on each other's result, they can run in parallel.
  final results = await Future.wait([
    client.dio.get('/api/schools/$schoolId'),   // results[0] — school name
    client.dio.get('/api/dashboard/'),           // results[1] — today's stat counts
    client.dio.get('/api/dashboard/trends'),     // results[2] — 30 days of attendance history
  ]);

  // Destructure the results list by index — matches the order above.
  final schoolResp = results[0];
  final dashResp   = results[1];
  final trendsResp = results[2];

  // Cast response body to a Map so we can access keys by name.
  // '?? {}' means: if the response body is null for any reason, use an empty map (no crash).
  final dashData = dashResp.data as Map<String, dynamic>? ?? {};

  // Each field uses 'as num?' because JSON numbers can decode as int OR double.
  // .toInt() normalises to int. '?? 0' is the fallback if the key is missing.
  final present       = (dashData['dailyAttendance'] as num?)?.toInt() ?? 0; // present + late combined
  final absentToday   = (dashData['absentToday']     as num?)?.toInt() ?? 0;
  final totalStudents = (dashData['totalStudents']   as num?)?.toInt() ?? 0;
  final totalTeachers = (dashData['totalTeachers']   as num?)?.toInt() ?? 0;
  final lateToday     = (dashData['lateToday']       as num?)?.toInt() ?? 0;

  // The trends endpoint wraps the array under the key 'attendanceTrends'.
  // 'as List<dynamic>?' handles the case where the key exists but is null.
  // '?? []' means: if null, use an empty list so the .map() below still runs safely.
  final rawTrends = (trendsResp.data?['attendanceTrends'] as List<dynamic>?) ?? [];

  // Convert each raw JSON row into a typed AttendanceTrendPoint.
  // .map() transforms every item in the list. .toList() finalises it as a List.
  final trendData = rawTrends.map((row) {
    // Each row is a JSON object — cast to Map so we can access fields by key.
    final m = row as Map<String, dynamic>;
    return AttendanceTrendPoint(
      date:         m['attendance_date'] as String? ?? '',
      presentCount: (m['present_count']  as num?)?.toInt() ?? 0,
      lateCount:    (m['late_count']     as num?)?.toInt() ?? 0,
      absentCount:  (m['absent_count']   as num?)?.toInt() ?? 0,
    );
  }).toList();


  // Convert raw student maps to typed AppUser objects using the shared mapper function.
  final recentStudents = recentRaw.map(nodeStudentToAppUser).toList();

  // School name is nested: response.data → 'data' → 'name'
  // The schools endpoint wraps the result under a 'data' key (unlike the dashboard endpoint).
  final schoolName = (schoolResp.data?['data']?['name'] as String?) ?? 'EduAir School';

  // Build and return the single AdminHomeData object.
  // _buildTrendLabel() runs the week-over-week calculation and returns the label string.
  return AdminHomeData(
    totalStudents:  totalStudents,
    presentToday:   present,
    absentToday:    absentToday,
    totalTeachers:  totalTeachers,
    lateToday:      lateToday,
    recentStudents: recentStudents,
    schoolName:     schoolName,
    trendData:      trendData,
    trendLabel:     _buildTrendLabel(trendData),
  );
});
