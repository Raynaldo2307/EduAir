// TeacherHomeScreen
// ----------------
// Role:
// - Main dashboard for a logged-in teacher inside the TeacherShell.
// - Greets the teacher and shows what's important today.
//
// Responsibilities:
// - Display basic identity info (name, staff ID, avatar) from [userProvider].
// - Card 1: Attendance-batch-aware roll status for the teacher's homeroom class.
//   Watches [teacherAttendanceForDateProvider] and reacts to loading/empty/done states.
// - Card 2: Static quick-action (homework review placeholder).
// - Quick links grid, today's classes, upcoming events.
//
// Dark-mode: all colours route through Theme.of(context).colorScheme.
// The InfoCard widget handles its own dark-mode background swap.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/shared/widgets/app_greeting_header.dart';
import 'package:edu_air/src/features/teacher/home/widgets/info_card.dart';
import 'package:edu_air/src/features/teacher/home/widgets/teacher_quick_link_grid.dart';
import 'package:edu_air/src/features/shared/widgets/today_classes_section.dart';
import 'package:edu_air/src/features/shared/widgets/upcoming_events_section.dart';
import 'package:edu_air/src/models/class_session.dart';

// Attendance awareness
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/Teacher/attendance/teacher_attendance_providers.dart';
import 'package:edu_air/src/features/teacher/attendance/domain/teacher_attendance_models.dart';

class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key, required this.onSelectTab});

  /// Callback from the shell to switch bottom nav tab.
  /// Teacher: 0=Home  1=Students  2=Attendance  3=Settings
  final void Function(int index) onSelectTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── 1. Identity ──────────────────────────────────────────────────────────
    final user = ref.watch(userProvider);

    final name = (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName
        : 'Teacher';

    final teacherId = (user?.studentId?.isNotEmpty ?? false)
        ? user!.studentId!
        : '—';

    final department = (user?.teacherDepartment?.trim().isNotEmpty ?? false)
        ? user!.teacherDepartment!
        : 'EduAir School';

    // ── 2. Attendance-batch-aware roll status hook ────────────────────────────
    //
    // We query [teacherAttendanceForDateProvider] for the teacher's homeroom
    // class today.  The provider is a FutureProvider.family.autoDispose, so it:
    //   • reacts automatically when the query key changes
    //   • disposes itself when this widget leaves the tree
    //   • returns Map<studentUid, AttendanceStatus> — empty = no roll yet
    //
    final homeroomClassId = user?.homeroomClassId;
    final homeroomClassName = user?.homeroomClassName;
    final schoolId = user?.schoolId;
    final todayKey = AttendanceDay.dateKeyFor(DateTime.now());

    AsyncValue<Map<String, AttendanceStatus>>? rollAsync;

    final hasHomeroom = homeroomClassId != null &&
        homeroomClassId.isNotEmpty &&
        homeroomClassName != null &&
        homeroomClassName.isNotEmpty &&
        schoolId != null &&
        schoolId.isNotEmpty;

    if (hasHomeroom) {
      rollAsync = ref.watch(
        teacherAttendanceForDateProvider(
          TeacherAttendanceQuery(
            schoolId: schoolId,
            classOption: TeacherClassOption(
              classId: homeroomClassId,
              className: homeroomClassName,
            ),
            dateKey: todayKey,
          ),
        ),
      );
    }

    // ── 3. Hero cards (dynamic roll status + static second card) ─────────────
    final heroCards = _buildTeacherHeroCards(
      rollAsync: rollAsync,
      homeroomClassName: homeroomClassName,
      onGoToAttendance: () => onSelectTab(2),
    );

    // ── 4. Quick links ───────────────────────────────────────────────────────
    const quickLinks = [
      QuickLinkItem(
        icon: Icons.event_available_outlined,
        label: 'Attendance',
        backgroundColor: Color(0xFFE8F2FF),
        iconColor: Color(0xFF4A7CFF),
        routeName: '/teacherAttendance',
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

    // ── 5. Today's classes (still demo data) ─────────────────────────────────
    final now = DateTime.now();
    DateTime todayAt(int hour, int minute) =>
        DateTime(now.year, now.month, now.day, hour, minute);

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

    // ── 6. Upcoming events (shared widget, still demo) ────────────────────────
    const upcomingEvents = [
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

    // ── 7. Build the page ─────────────────────────────────────────────────────
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              AppGreetingHeader(
                name: name,
                id: teacherId,
                initials: user?.initials ?? 'U',
                subtitle: department,
                avatarUrl: user?.photoUrl,
              ),

              const SizedBox(height: 18),

              // InfoCardsRow handles its own background + dark mode internally
              InfoCardsRow(cards: heroCards),

              const SizedBox(height: 24),

              // Dashboard title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: cs.onSurface,
                      ),
                ),
              ),

              const SizedBox(height: 15),

              // Quick links grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: QuickLinksGrid(
                  links: quickLinks,
                  onItemTap: (context, item) {
                    if (item.label == 'Attendance') {
                      Navigator.of(context).pushNamed('/teacherAttendance');
                    } else if (item.label == 'Student Info') {
                      onSelectTab(1);
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Today's classes
              TodayClassesSection(
                sessions: todayClasses,
                onViewAll: () {},
              ),

              const SizedBox(height: 24),

              // Upcoming events
              UpcomingEventsSection(
                events: upcomingEvents,
                onViewAll: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero card builder ──────────────────────────────────────────────────────────
//
// Four states for Card 1 (batch-aware):
//   • rollAsync == null   → no homeroom class assigned
//   • isLoading           → querying the API
//   • hasError            → network / server problem
//   • map.isEmpty         → roll not yet taken today
//   • map.isNotEmpty      → roll submitted — shows present count
//
// Card 2 is always static (homework placeholder).

List<InfoCardData> _buildTeacherHeroCards({
  required AsyncValue<Map<String, AttendanceStatus>>? rollAsync,
  required String? homeroomClassName,
  required VoidCallback onGoToAttendance,
}) {
  final className =
      (homeroomClassName?.isNotEmpty ?? false) ? homeroomClassName! : 'your class';

  final InfoCardData rollCard;

  if (rollAsync == null) {
    // No homeroom class set — still give the teacher a useful CTA
    rollCard = InfoCardData(
      title: 'Take today\'s attendance',
      subtitle: 'Mark your class as present or absent.',
      ctaLabel: 'Mark Now',
      backgroundColor: const Color(0xFFFFF8E8), // warm cream
      imageUrl: 'assets/images/teacher_hero_new_student.png',
      onTap: onGoToAttendance,
    );
  } else if (rollAsync.isLoading) {
    rollCard = InfoCardData(
      title: 'Checking today\'s roll...',
      subtitle: 'Loading attendance for $className.',
      backgroundColor: const Color(0xFFE8F2FF), // soft blue
      imageUrl: 'assets/images/teacher_hero_new_student.png',
      onTap: onGoToAttendance,
    );
  } else if (rollAsync.hasError) {
    rollCard = InfoCardData(
      title: 'Could not load roll',
      subtitle: 'Tap to open attendance and try again.',
      ctaLabel: 'Open',
      backgroundColor: const Color(0xFFFFF3CD), // soft amber — warning
      imageUrl: 'assets/images/teacher_hero_new_student.png',
      onTap: onGoToAttendance,
    );
  } else {
    final rollMap = rollAsync.valueOrNull ?? {};

    if (rollMap.isEmpty) {
      // Roll not taken yet
      rollCard = InfoCardData(
        title: 'Take today\'s roll',
        subtitle: 'Mark attendance for $className.',
        ctaLabel: 'Mark Now',
        backgroundColor: const Color(0xFFFFF8E8), // warm cream — action needed
        imageUrl: 'assets/images/teacher_hero_new_student.png',
        onTap: onGoToAttendance,
      );
    } else {
      // Roll submitted — count present-like vs total
      final presentCount =
          rollMap.values.where((s) => s.isPresentLike).length;
      final totalCount = rollMap.length;

      rollCard = InfoCardData(
        title: 'Roll done ✓',
        subtitle:
            '$presentCount / $totalCount present in $className.',
        ctaLabel: 'View Report',
        backgroundColor: const Color(0xFFE8F8EE), // soft green — done
        imageUrl: 'assets/images/teacher_hero_new_student.png',
        onTap: onGoToAttendance,
      );
    }
  }

  return [
    rollCard,
    // Card 2: static quick-action
    InfoCardData(
      title: 'Review homework submissions',
      subtitle: 'Check and grade student work.',
      ctaLabel: 'Review',
      backgroundColor: const Color(0xFFF0EAFF), // soft lavender
      imageUrl: 'assets/images/teacher_hero_homework.png',
    ),
  ];
}
