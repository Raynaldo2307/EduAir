// lib/src/features/shared/domain/app_module.dart

library;

class AppFormula {
  final String title;
  final String user; // Now lists specific UserRoles
  final String solution;
  final String metrics;

  const AppFormula({
    required this.title,
    required this.user,
    required this.solution,
    required this.metrics,
  });

  String summary() {
    return '''
Title: $title
User: $user
Solution: $solution
Metrics: $metrics
''';
  }
}

// -------------------- Core Modules --------------------

// 1️⃣ Attendance Module
// 1️⃣ Attendance Module
final attendanceModule = AppFormula(
  title: "Attendance",
  user: "Teacher, Admin, Student, Parent",
  solution:
      "Location-aware virtual register that combines time-window and geofenced attendance. Students clock in (08:00–16:00) and clock out with time-based logic (Early 08:00–08:30, Late after 08:30 with required reason), automatic Absent marking for missed days, and auto clock-out after 16:00. Every clock event stores GPS and can be reviewed on a map. On top of this, per-student/day geofence profiles define where a student is allowed to check in/out (e.g., Wed/Thu at Stony Hill campus, other days at Up Park), with band types (fixed vs floating), outside-area policies (block vs allow+flag), and incident logs whenever a fixed-band student checks in/out outside their zone. Admins and teachers get date-range views, override tools, and insights dashboards based on this data. Icon: calendar_today_rounded, Color: Green, Route: /attendance.",
  metrics:
      "On-time clock-in rate (early vs late), % present/absent per week, count of outside-area attempts vs in-zone check-ins, number and status of geofence incidents (open/acknowledged), frequency of admin overrides, days auto-marked absent, parent alert delivery rate, and weekly insights such as at-risk (high absence), frequent late, and trend vs last week.",
);

// 2️⃣ Exam Prep Module
final examPrepModule = AppFormula(
  title: "Exam Prep",
  user: "Student, Teacher",
  solution:
      "Digital exam prep dashboard (Icon: school_rounded, Color: Blue) with daily study tasks, reminders, progress tracking, and performance analytics for CSEC/PEP. Route: /examPrep.",
  metrics:
      "% of exam tasks completed, average time spent, improvement in mock tests, adherence to study schedule",
);

// 3️⃣ Communication Hub (Messaging)
final messagingModule = AppFormula(
  title: "Messages",
  user: "All Roles", // Visibility: Everyone
  solution:
      "In-app messaging system (Icon: chat_bubble_outline_rounded, Color: Orange) with channels for announcements, homework, events, and direct Parent-Teacher/Student-Teacher messages. Route: /messages.",
  metrics:
      "Messages sent, messages read, response times, active users per channel",
);

// 4️⃣ Resources & Assignments Module
final resourceModule = AppFormula(
  title: "Resources & H.W.",
  user: "Student, Teacher",
  solution:
      "Digital repository (Icon: book_rounded, Color: Purple) for study guides, PDFs, videos; assignments submitted and graded digitally. Route: /resources.",
  metrics:
      "% of assignments submitted, resource download/access counts, average grades",
);

// 5️⃣ Parent Portal Module
final parentPortalModule = AppFormula(
  title: "Parent Portal",
  user: "Parent, Admin",
  solution:
      "Dedicated portal (Icon: family_restroom_rounded, Color: Pink) showing real-time attendance, completed assignments, behavior reports, and notifications. Route: /parentPortal.",
  metrics:
      "Parent login rate, report views, notifications acknowledged, engagement with student progress",
);

// 6️⃣ Alerts & Emergency Module
final alertsModule = AppFormula(
  title: "Alerts",
  user: "All Roles",
  solution:
      "Push notification system (Icon: notification_important_rounded, Color: Red) for urgent updates and school announcements, with admin-controlled scheduling. Route: /alerts.",
  metrics: "Alerts acknowledged/opened, response rate, reduced missed events",
);

// -------------------- Module List --------------------
final eduAirModules = [
  attendanceModule,
  examPrepModule,
  messagingModule,
  resourceModule,
  parentPortalModule,
  alertsModule,
];
