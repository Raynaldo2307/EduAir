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
import 'package:edu_air/src/features/common/widgets/today_classes_section.dart';
import 'package:edu_air/src/models/class_session.dart';
import 'package:edu_air/src/features/timetable/domain/timetable_entry.dart';
import 'package:edu_air/src/features/Teacher/lesson_attendance/presentation/lesson_roll_page.dart';
import 'package:edu_air/src/features/timetable/presentation/teacher_timetable_screen.dart';

// Attendance awareness
import 'package:edu_air/src/features/attendance/domain/attendance_models.dart';
import 'package:edu_air/src/features/Teacher/attendance/teacher_attendance_providers.dart';
import 'package:edu_air/src/features/teacher/attendance/domain/teacher_attendance_models.dart';

class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key, required this.onSelectTab});

  /// Callback from the shell to switch bottom nav tab.
  /// Teacher tabs: 0=Home  1=Students  2=Attendance  3=Notices  4=Settings
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

    // Header subtitle: real school name + role tag (e.g. "Papine High School ·
    // Teacher"). schoolName comes from the API now — no hardcoded id→name table.
    final schoolName = (user?.schoolName?.trim().isNotEmpty ?? false)
        ? user!.schoolName!
        : 'EduAir';
    final subtitle = '$schoolName · ${_roleLabel(user?.role)}';

    // ── 2. Attendance-batch-aware roll status hook ────────────────────────────
    //
    // We query [teacherAttendanceForDateProvider] for the teacher's homeroom
    // class today.  The provider is a FutureProvider.family.autoDispose, so it:
    //   • reacts automatically when the query key changes
    //   • disposes itself when this widget leaves the tree
    //   • returns Map<studentUid, TeacherAttendanceMark> — empty = no roll yet
    //
    final homeroomClassId = user?.homeroomClassId;
    final homeroomClassName = user?.homeroomClassName;
    final schoolId = user?.schoolId;
    final todayKey = AttendanceDay.dateKeyFor(DateTime.now());

    AsyncValue<Map<String, TeacherAttendanceMark>>? rollAsync;

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

    // ── 5. Today's classes — the teacher's real periods for today ────────────
    //
    // teaching-today is scoped to THIS teacher server-side (by JWT user id),
    // across every class she teaches. We pass the device weekday so the result
    // stays correct in the school's timezone. Rows map onto ClassSession.
    // loading / error / empty all collapse to an empty list — and
    // TodayClassesSection hides itself on an empty list, so the section simply
    // doesn't appear. Never demo data, never a broken card.
    final todayWeekday = _weekdayCode(DateTime.now());
    // Keep the real periods (not just their display sessions) so a tapped tile
    // can open THAT period's lesson roll — the tile index maps 1:1 to an entry.
    final todayEntries = ref.watch(teachingTodayProvider(todayWeekday)).maybeWhen(
          data: (entries) => entries,
          orElse: () => const <TimetableEntry>[],
        );
    final todayClasses = todayEntries.map(_entryToSession).toList();

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
                subtitle: subtitle,
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
                    // Tiles that map to a bottom-nav tab switch to it (keeps the
                    // nav bar). Time Table has no tab → push it. Unbuilt features
                    // say "coming soon" instead of being dead taps.
                    switch (item.label) {
                      case 'Attendance':
                        onSelectTab(2);
                      case 'Student Info':
                        onSelectTab(1);
                      case 'Notice':
                        onSelectTab(3);
                      case 'Time Table':
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const TeacherTimetableScreen(),
                        ));
                      default:
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${item.label} is coming soon')),
                        );
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Today's classes — tap a period to open its lesson roll.
              TodayClassesSection(
                sessions: todayClasses,
                onViewAll: () {},
                onTap: (i) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => LessonRollPage(entry: todayEntries[i]),
                  ));
                },
              ),

              // Upcoming Events intentionally removed — it showed hardcoded 2024
              // demo data. Re-add once a real events/notices source exists.
            ],
          ),
        ),
      ),
    );
  }
}

// DateTime.weekday is Mon=1..Sun=7 — index into the API's day codes.
String _weekdayCode(DateTime d) =>
    const ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'][d.weekday - 1];

// Maps one of the teacher's own timetable periods onto the ClassSession the
// Today's-classes tiles render. The teacher's name is left blank — it's her own
// dashboard, so the useful label is the CLASS (groupName), not the teacher. The
// API gives times as 'HH:mm'; we anchor them to today so the tile can show a
// clock range. No online concept yet → isOnline stays false.
ClassSession _entryToSession(TimetableEntry e) {
  final now = DateTime.now();
  DateTime at(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(now.year, now.month, now.day, h, m);
  }

  return ClassSession(
    id: e.id.toString(),
    subjectName: e.subject,
    groupName: e.className ?? 'Class',
    teacherName: '',
    startTime: at(e.startTime),
    endTime: at(e.endTime),
    room: e.room ?? '',
    isOnline: false,
  );
}

// Maps a role code to a display label for the header tag. Generic so the same
// header reads correctly for any role if reused (student/teacher/admin/…).
String _roleLabel(String? role) {
  switch (role) {
    case 'teacher':   return 'Teacher';
    case 'admin':     return 'Admin';
    case 'principal': return 'Principal';
    case 'student':   return 'Student';
    case 'parent':    return 'Parent';
    default:          return 'Staff';
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
  required AsyncValue<Map<String, TeacherAttendanceMark>>? rollAsync,
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
          rollMap.values.where((m) => m.status.isPresentLike).length;
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
