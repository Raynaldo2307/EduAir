// TeacherHomeScreen
// ----------------
// Role:
// - Main dashboard for a logged-in teacher inside the TeacherShell.
// - Greets the teacher and shows what’s important today.
//
// Responsibilities:
// - Display basic identity info (name, staff ID, avatar) from [userProvider].
// - Highlight key actions via "hero" cards (e.g. new student entry, homework to review).
// - Expose quick links to core teacher features (Attendance, Time Table, Student Info, etc.).
// - Show today's classes / lectures.
// - Show upcoming school events.
//
// Current state:
// - Uses hard-coded demo data for hero cards, quick links, today classes, and upcoming events.
// - Uses fallback values for name / teacherId when user data is missing.
//
// Future improvements:
// - Replace hard-coded lists with dynamic data from Firestore / backend.
// - Make quick links tappable and navigate to real feature pages.
// - Personalize hero cards and today classes from the teacher’s timetable.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';

// Teacher-specific widgets
import 'package:edu_air/src/features/teacher/home/widgets/greeting.dart';
import 'package:edu_air/src/features/teacher/home/widgets/info_card.dart';
import 'package:edu_air/src/features/teacher/home/widgets/teacher_quick_link_grid.dart';

// Shared widgets / models
import 'package:edu_air/src/features/shared/widgets/today_classes_section.dart';
import 'package:edu_air/src/features/shared/widgets/upcoming_events_section.dart';
import 'package:edu_air/src/models/class_session.dart';

class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ----- 1. Who is logged in? ------------------------------------------------
    final user = ref.watch(userProvider);

    final name = (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName
        : 'Dev';

    // For now we reuse studentId as a generic ID until you have a staffId field.
    final teacherId = (user?.studentId?.isNotEmpty ?? false)
        ? user!.studentId!
        : 'S8745';

    final department = (user?.teacherDepartment?.trim().isNotEmpty ?? false)
        ? user!.teacherDepartment!
        : 'Mathematics Department';

    // ----- 2. Hero info cards (teacher focused) --------------------------------
    final heroCards = [
      const InfoCardData(
        title: 'Check new student entry in your class',
        subtitle: 'New students waiting for review.',
        imageUrl: 'assets/images/teacher_hero_new_student.png',
        ctaLabel: 'Check Now',
        backgroundColor: Color(0xFFFDE3D0), // soft peach
      ),
      const InfoCardData(
        title: 'Review homework submissions',
        subtitle: '5 assignments submitted today.',
        imageUrl: 'assets/images/teacher_hero_homework.png',
        ctaLabel: 'Review',
        backgroundColor: Color(0xFFE1F5FE), // light blue
      ),
    ];

    // ----- 3. Quick links (teacher tools) -------------------------------------
    final quickLinks = const [
      QuickLinkItem(
        icon: Icons.event_available_outlined,
        label: 'Attendance',
        backgroundColor: Color(0xFFE8F2FF),
        iconColor: Color(0xFF4A7CFF),
      ),
      QuickLinkItem(
        icon: Icons.description_outlined,
        label: 'Teachers Note',
        backgroundColor: Color(0xFFF5EBFF),
        iconColor: Color(0xFF9B51E0),
      ),
      QuickLinkItem(
        icon: Icons.assignment_turned_in_outlined,
        label: 'Leave',
        backgroundColor: Color(0xFFE6F6F3),
        iconColor: Color(0xFF2D9CDB),
      ),
      QuickLinkItem(
        icon: Icons.calendar_today_outlined,
        label: 'Time Table',
        backgroundColor: Color(0xFFEFF4FF),
        iconColor: Color(0xFF4A5568),
      ),
      QuickLinkItem(
        icon: Icons.edit_note_outlined,
        label: 'Home Work',
        backgroundColor: Color(0xFFF8F2DC),
        iconColor: Color(0xFFB7791F),
      ),
      QuickLinkItem(
        icon: Icons.badge_outlined,
        label: 'Student Info',
        backgroundColor: Color(0xFFFDE9EC),
        iconColor: Color(0xFFE65D7B),
      ),
      QuickLinkItem(
        icon: Icons.chat_bubble_outline,
        label: 'Message',
        backgroundColor: Color(0xFFF6EAFE),
        iconColor: Color(0xFFAA7AE0),
      ),
      QuickLinkItem(
        icon: Icons.campaign_outlined,
        label: 'Notice',
        backgroundColor: Color(0xFFE7F7EC),
        iconColor: Color(0xFF2F9E44),
      ),
    ];

    final now = DateTime.now();
    DateTime todayAt(int hour, int minute) =>
        DateTime(now.year, now.month, now.day, hour, minute);

    // ----- 4. Today’s classes / lectures --------------------------------------
    final todayClasses = [
      ClassSession(
        id: 'class-1',
        subjectName: 'Maths',
        groupName: '7th B',
        teacherName: name,
        startTime: todayAt(10, 30),
        endTime: todayAt(11, 30),
        room: 'Room 12',
        isOnline: false,
      ),
      ClassSession(
        id: 'class-2',
        subjectName: 'Science',
        groupName: '9th A',
        teacherName: name,
        startTime: todayAt(12, 0),
        endTime: todayAt(12, 45),
        room: 'Lab 2',
        isOnline: true,
      ),
    ];

    // ----- 5. Upcoming events (shared widget) ---------------------------------
    final upcomingEvents = const [
      UpcomingEvent(
        title: 'Staff meeting',
        dateLabel: 'Nov 22, 2024',
        imageUrl: 'assets/images/event_staff_meeting.png',
        fallbackColor: Color(0xFFE1F5FE),
      ),
      UpcomingEvent(
        title: 'Science fair',
        dateLabel: 'Dec 1, 2024',
        imageUrl: 'assets/images/event_science_fair.png',
        fallbackColor: Color(0xFFE1F5FE),
      ),
      UpcomingEvent(
        title: 'Parent teacher conference',
        dateLabel: 'Dec 5, 2024',
        imageUrl: 'assets/images/event_parent_meeting.png',
        fallbackColor: Color(0xFFE1F5FE),
      ),
    ];

    // ----- 6. Build the page --------------------------------------------------
    return Scaffold(
    body:SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (name, ID, avatar)
            GreetingHeader(
              name: name,
              teacherId: teacherId,
              teacherDepartment: department,
              avatarUrl: user?.photoUrl,
            ),

            const SizedBox(height: 18),

            // Hero cards (no green strip for teacher, matches your FlutterFlow UI)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.heroStripBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: InfoCardsRow(cards: heroCards),
            ),
           

          //InfoCardsRow(cards: heroCards),
            
            const SizedBox(height: 24),

            // Quick links title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Dashboard',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary),
              ),
            ),

            const SizedBox(height: 15),

            // Quick links grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: QuickLinksGrid(links: quickLinks),
            ),

            const SizedBox(height: 24),

            // Today lectures / classes
            TodayClassesSection(
              sessions: todayClasses,
              onViewAll: () {
                // TODO: navigate to full timetable screen
              },
            ),

            const SizedBox(height: 24),

            // Upcoming events (shared between student + teacher)
            UpcomingEventsSection(
              events: upcomingEvents,
              onViewAll: () {
                // TODO: navigate to full events screen
              },
            ),
          ],
        ),
      ),
    ),
    );
  
  }
}
