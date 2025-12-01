/// EduAir AppModule Dashboard - Copy-Paste Ready
library;

class AppFormula {
  final String problem;
  final String user;
  final String solution;
  final String metrics;

  const AppFormula({
    required this.problem,
    required this.user,
    required this.solution,
    required this.metrics,
  });

  String summary() {
    return '''
Problem: $problem
User: $user
Solution: $solution
Metrics: $metrics
''';
  }
}

// -------------------- Core Modules --------------------

// 1️⃣ Attendance Module
final attendanceModule = AppFormula(
  problem: "Teachers cannot reliably track student attendance due to paper-based systems, damaged infrastructure, and inconsistent communication in rural schools.",
  user: "Students, Teachers, Administrators",
  solution: "Digital attendance system with check-in, offline support, automatic reporting, and alerts for low attendance.",
  metrics: "Daily attendance recorded, % students present, reports generated, students flagged for low attendance"
);

// 2️⃣ Exam Prep Module
final examPrepModule = AppFormula(
  problem: "Students lack structured revision schedules and real-time progress tracking for CSEC/JSAT exams.",
  user: "Students, Teachers",
  solution: "Digital exam prep dashboard with daily study tasks, reminders, progress tracking, and performance analytics.",
  metrics: "% of exam tasks completed, average time spent, improvement in mock tests, adherence to study schedule"
);

// 3️⃣ Messaging Module
final messagingModule = AppFormula(
  problem: "Communication between students, teachers, and administrators is fragmented and slow, often relying on WhatsApp or paper notices.",
  user: "Students, Teachers, Administrators",
  solution: "In-app messaging system with channels for announcements, homework, events, and direct messages.",
  metrics: "Messages sent, messages read, response times, active users per channel"
);

// 4️⃣ Parent Reporting Module
final parentReportingModule = AppFormula(
  problem: "Parents have limited visibility into student attendance, homework completion, and exam progress, reducing their ability to support students at home.",
  user: "Parents, Teachers, Administrators",
  solution: "Parent portal showing attendance reports, completed assignments, exam prep progress, and notifications for important updates.",
  metrics: "Parent logins, report views, notifications acknowledged, engagement with student progress"
);

// -------------------- Additional Modules --------------------

// 5️⃣ Parent-Student Engagement Module
final parentEngagementModule = AppFormula(
  problem: "Parents have limited visibility into daily student progress, homework, and attendance",
  user: "Parents, Students, Teachers",
  solution: "Push notifications, weekly dashboards, feedback system, and parent-student-teacher interactions",
  metrics: "Parent login rate, notifications viewed, feedback interactions, student engagement improvement"
);

// 6️⃣ Resource & Assignment Module
final resourceModule = AppFormula(
  problem: "Students in rural areas lack centralized access to study materials, assignments, or exam prep resources",
  user: "Students, Teachers",
  solution: "Digital repository for study guides, PDFs, videos; assignments submitted and graded digitally; progress tracked automatically",
  metrics: "% of assignments submitted, resource download/access counts, average grades"
);

// 7️⃣ Alerts & Emergency Module
final alertsModule = AppFormula(
  problem: "Schools need to communicate urgent updates, but students and parents often miss them",
  user: "Students, Parents, Teachers, Administrators",
  solution: "Push alerts for events, optional SMS fallback, admin-controlled scheduling",
  metrics: "Alerts acknowledged/opened, response rate, reduced missed events"
);

// 8️⃣ Student Well-being / Behavior Module
final wellbeingModule = AppFormula(
  problem: "Teachers need to track behavior, engagement, and well-being metrics that impact learning outcomes",
  user: "Students, Teachers, Parents",
  solution: "Track participation, mood check-ins, behavior points; dashboards; early warning system for at-risk students",
  metrics: "Participation rates, behavior incidents logged, early interventions triggered"
);

// 9️⃣ Parent-Teacher Communication Module
final parentTeacherCommModule = AppFormula(
  problem: "Direct communication between teachers and parents is inconsistent and ineffective",
  user: "Parents, Teachers",
  solution: "Dedicated messaging per student, auto-shared attendance/grades, scheduled virtual parent-teacher conferences",
  metrics: "Messages exchanged per student per week, % of parents actively engaging, meeting attendance"
);

// -------------------- Module List --------------------
final eduAirModules = [
  attendanceModule,
  examPrepModule,
  messagingModule,
  parentReportingModule,
  parentEngagementModule,
  resourceModule,
  alertsModule,
  wellbeingModule,
  parentTeacherCommModule,
];