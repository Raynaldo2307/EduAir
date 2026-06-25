import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/admin/home/application/admin_home_provider.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class ClassPerformanceItem {
  final String className;
  final double attendanceRate; // 0.0 – 100.0 percent

  const ClassPerformanceItem({
    required this.className,
    required this.attendanceRate,
  });

  // Convert percent to 0–1 fraction for progress bars and bar heights.
  double get fraction => (attendanceRate / 100).clamp(0.0, 1.0);
}

class DayOfWeekStat {
  final String dayName;       // full name from MySQL: 'Monday', 'Tuesday', …
  final double attendanceRate; // 0.0 – 100.0 percent

  const DayOfWeekStat({
    required this.dayName,
    required this.attendanceRate,
  });

  // First 3 chars used as the bar label in the chart.
  String get shortName => dayName.length >= 3 ? dayName.substring(0, 3) : dayName;

  double get fraction => (attendanceRate / 100).clamp(0.0, 1.0);
}

// Single object that feeds every card on the analytics screen.
class AdminAnalyticsData {
  final int chronicAbsentees;
  final double avgAttendance;
  final List<TopAbsentStudent> topAbsent;
  final List<ClassPerformanceItem> classPerformance;
  final List<DayOfWeekStat> dayOfWeek;
  final List<StaffConsistency> staffConsistency;

  const AdminAnalyticsData({
    required this.chronicAbsentees,
    required this.avgAttendance,
    required this.topAbsent,
    required this.classPerformance,
    required this.dayOfWeek,
    required this.staffConsistency,
  });
}

// ─── Providers ────────────────────────────────────────────────────────────────

// The time window selected on the analytics control panel. Drives the tab UI
// and the bar colour. Base values: '30' | '90' | 'term'.
// autoDispose: resets to the 30-day default each time the admin opens the screen.
final analyticsRangeProvider =
    StateProvider.autoDispose<String>((ref) => '30');

// Which term the admin picked from the dropdown (only meaningful when the range
// is 'term'). null = the CURRENT term (the default). autoDispose with the screen.
final selectedAnalyticsTermProvider =
    StateProvider.autoDispose<int?>((ref) => null);

// The exact value sent to the backend ?days=. For 30/90 it's just the range;
// for 'term' it folds in the picked term id ('term:5'), or stays 'term' for the
// current term. ONE place builds the wire value so every card agrees on the
// window — change the term and all cards re-fetch together.
final analyticsDaysParamProvider = Provider.autoDispose<String>((ref) {
  final range = ref.watch(analyticsRangeProvider);
  if (range != 'term') return range;
  final termId = ref.watch(selectedAnalyticsTermProvider);
  return termId == null ? 'term' : 'term:$termId';
});

// Fetches all analytics screen data in 5 parallel calls.
// autoDispose: destroyed when admin leaves the analytics tab — never shows stale numbers.
// Watches analyticsRangeProvider, so changing the window re-runs every call.
final adminAnalyticsProvider =
    FutureProvider.autoDispose<AdminAnalyticsData>((ref) async {
  final client = ref.read(apiClientProvider);
  final days   = ref.watch(analyticsDaysParamProvider);
  final query  = {'days': days};

  final results = await Future.wait([
    client.dio.get('/api/analytics/summary',           queryParameters: query), // results[0]
    client.dio.get('/api/analytics/top-absent',        queryParameters: query), // results[1]
    client.dio.get('/api/analytics/class-performance', queryParameters: query), // results[2]
    client.dio.get('/api/analytics/day-of-week',       queryParameters: query), // results[3]
    client.dio.get('/api/analytics/staff-consistency', queryParameters: query), // results[4]
  ]);

  // ── Summary ──────────────────────────────────────────────────────────────
  final summaryData = results[0].data as Map<String, dynamic>? ?? {};
  final chronicAbsentees = (summaryData['chronicAbsentees'] as num?)?.toInt() ?? 0;
  final avgAttendance    = (summaryData['avgAttendance']    as num?)?.toDouble() ?? 0.0;

  // ── Top Absent Students ───────────────────────────────────────────────────
  final rawStudents = (results[1].data?['students'] as List<dynamic>?) ?? [];
  final topAbsent = rawStudents.map((row) {
    final m = row as Map<String, dynamic>;
    return TopAbsentStudent(
      firstName:      m['first_name']      as String? ?? '',
      lastName:       m['last_name']       as String? ?? '',
      className:      m['class_name']      as String? ?? '—',
      absencePercent: (m['absence_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }).toList();

  // ── Class Performance ─────────────────────────────────────────────────────
  final rawClasses = (results[2].data?['classes'] as List<dynamic>?) ?? [];
  final classPerformance = rawClasses.map((row) {
    final m = row as Map<String, dynamic>;
    return ClassPerformanceItem(
      className:      m['class_name']      as String? ?? '—',
      attendanceRate: (m['attendance_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }).toList();

  // ── Day-of-Week ───────────────────────────────────────────────────────────
  final rawDays = (results[3].data?['days'] as List<dynamic>?) ?? [];
  final dayOfWeek = rawDays.map((row) {
    final m = row as Map<String, dynamic>;
    return DayOfWeekStat(
      dayName:        m['day_name']        as String? ?? '',
      attendanceRate: (m['attendance_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }).toList();

  // ── Staff Consistency ─────────────────────────────────────────────────────
  final rawStaff = (results[4].data?['staff'] as List<dynamic>?) ?? [];
  final staffConsistency = rawStaff.map((row) {
    final m = row as Map<String, dynamic>;
    return StaffConsistency(
      firstName:  m['first_name']  as String? ?? '',
      lastName:   m['last_name']   as String? ?? '',
      department: m['department']  as String? ?? 'General',
      // Wired forward: faces show once the analytics staff query returns
      // photo_url (backend follow-up); null today → shared initials avatar.
      photoUrl:   m['photo_url']   as String?,
    );
  }).toList();

  return AdminAnalyticsData(
    chronicAbsentees: chronicAbsentees,
    avgAttendance:    avgAttendance,
    topAbsent:        topAbsent,
    classPerformance: classPerformance,
    dayOfWeek:        dayOfWeek,
    staffConsistency: staffConsistency,
  );
});

// Fetches daily attendance counts for the given time range.
// The family param is the range key: '30', '90', or 'term'.
// autoDispose.family: each range is cached separately — switching tabs reuses the cache.
final analyticsTrendsProvider = FutureProvider.autoDispose
    .family<List<AttendanceTrendPoint>, String>((ref, days) async {
  final client = ref.read(apiClientProvider);
  final resp = await client.dio.get(
    '/api/analytics/trends',
    queryParameters: {'days': days},
  );
  final rawTrends = (resp.data?['attendanceTrends'] as List<dynamic>?) ?? [];
  return rawTrends.map((row) {
    final m = row as Map<String, dynamic>;
    return AttendanceTrendPoint(
      date:         m['attendance_date'] as String? ?? '',
      presentCount: (m['present_count']  as num?)?.toInt() ?? 0,
      lateCount:    (m['late_count']     as num?)?.toInt() ?? 0,
      absentCount:  (m['absent_count']   as num?)?.toInt() ?? 0,
    );
  }).toList();
});
