// StudentHomePage
// ----------------
// Role:
// - Acts as the main dashboard for a logged-in student inside the StudentShell.
// - Greets the student and shows a quick overview of what matters today.
//
// Responsibilities:
// - Display basic identity info (name, student ID, avatar) from [userProvider].
// - Highlight key actions via "hero" cards (e.g. homework to check, live class to join).
// - Expose quick links to core features (Attendance, Exams, Leave, Fees, Homework, etc.).
// - Show a preview of upcoming school events.
//
// Current state:
// - Uses hard-coded demo data for hero cards, quick links, and upcoming events.
// - Uses fallback values for name / studentId when user data is missing.
// - Layout is scrollable and uses AppTheme for consistent colors.
//
// Future improvements:
// - Replace hard-coded lists with dynamic data from Firestore / backend.
// - Make quick links tappable and navigate to real feature pages.
// - Personalize hero cards based on the student's current timetable and assignments.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/student/home/widgets/greeting_header.dart';
import 'package:edu_air/src/features/student/home/widgets/info_cards_row.dart';
import 'package:edu_air/src/features/student/home/widgets/quick_links_grid.dart';
import 'package:edu_air/src/features/shared/widgets/upcoming_events_section.dart';

class StudentHomePage extends ConsumerWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final name = (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName
        : 'Dev Cooper';
    final studentId = (user?.studentId?.isNotEmpty ?? false)
        ? user!.studentId!
        : 'S8745';

    final heroCards = [
      const InfoCardData(
        title: 'Check updated homework',
        subtitle: 'New work for you.',
        imageUrl: 'assets/images/home_hero_homework.png',
        ctaLabel: 'Check Now',
        backgroundColor: Color(0xFFFDE1E9),
      ),
      const InfoCardData(
        title: 'Join live class at 2:30 PM',
        subtitle: 'Don\'t miss today\'s session.',
        imageUrl: 'assets/images/home_hero_live.png',
        ctaLabel: 'Join Now',
        backgroundColor: Color(0xFFE1F5FE),
      ),
    ];

    final quickLinks = const [
      QuickLinkItem(
        icon: Icons.event_available_outlined,
        label: 'Attendance',
        backgroundColor: Color(0xFFE8F2FF),
        iconColor: Color(0xFF4A7CFF),
      ),
      QuickLinkItem(
        icon: Icons.description_outlined,
        label: 'Exam',
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
        icon: Icons.account_balance_outlined,
        label: 'Fees',
        backgroundColor: Color(0xFFEFF4FF),
        iconColor: Color(0xFF4A5568),
      ),
      QuickLinkItem(
        icon: Icons.edit_note_outlined,
        label: 'Homework',
        backgroundColor: Color(0xFFF8F2DC),
        iconColor: Color(0xFFB7791F),
      ),
      QuickLinkItem(
        icon: Icons.groups_outlined,
        label: 'Community',
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

    final upcomingEvents = const [
      UpcomingEvent(
        title: 'Inter-school football match',
        dateLabel: 'Nov 22, 2024',
        imageUrl: 'assets/images/event_football.png',
        fallbackColor: Color(0xFFE1F5FE),
      ),
      UpcomingEvent(
        title: 'Science project fair',
        dateLabel: 'Dec 1, 2024',
        imageUrl: 'assets/images/event_science_fair.png',
        fallbackColor: Color(0xFFE1F5FE),
      ),
      UpcomingEvent(
        title: 'Parent teacher meeting',
        dateLabel: 'Dec 5, 2024',
        imageUrl: 'assets/images/event_parent_meeting.png',
        fallbackColor: Color(0xFFE1F5FE),
      ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (name, ID, avatar)
            GreetingHeader(
              name: name,
              studentId: studentId,
              avatarUrl: user?.photoUrl,
            ),

            const SizedBox(height: 18),

            // ✅ Green strip behind hero cards only
            Container(
              decoration: BoxDecoration(
                color: AppTheme.heroStripBackground,
                borderRadius: BorderRadius.circular(24),
              ),

              padding: const EdgeInsets.symmetric(vertical: 12),
              child: InfoCardsRow(cards: heroCards),
            ),

            const SizedBox(height: 24),

            // "Dashboard" title
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: quickLinks
                    .map((link) => QuickLinkItemWidget(item: link))
                    .toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Upcoming events
            UpcomingEventsSection(events: upcomingEvents, onViewAll: () {}),
          ],
        ),
      ),
    );
  }
}
