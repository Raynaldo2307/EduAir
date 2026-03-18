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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/shared/widgets/app_greeting_header.dart';
import 'package:edu_air/src/features/student/home/widgets/info_cards_row.dart';
import 'package:edu_air/src/features/student/home/widgets/quick_links_grid.dart';

class StudentHomePage extends ConsumerWidget {
  const StudentHomePage({super.key, required this.onTapAttendance});

  /// Callback used when the "Attendance" quick link is tapped.
  /// The [StudentShell] passes this in to switch to the Calendar tab.
  final VoidCallback onTapAttendance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    final name = (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName
        : 'Student';

    final studentId = (user?.studentId?.isNotEmpty ?? false)
        ? user!.studentId!
        : '—';

    final heroCards = _buildHeroCards(onTapAttendance: onTapAttendance);
    final quickLinks = _buildQuickLinks(
      context: context,
      onTapAttendance: onTapAttendance,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (name, ID, avatar)
              AppGreetingHeader(
                name: name,
                id: studentId,
                initials: user?.initials ?? 'U',
                avatarUrl: user?.photoUrl,
              ),

              const SizedBox(height: 18),

              // Hero strip — adapts to dark mode
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.heroStripBackground,
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Quick links grid (4 x 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: QuickLinksGrid(links: quickLinks),
              ),

              const SizedBox(height: 20),

              // Upcoming events
              Text(
                'Upcoming Events',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.event_outlined, size: 40, color: Color(0xFFB0BEC5)),
                    SizedBox(height: 8),
                    Text(
                      'No upcoming events',
                      style: TextStyle(color: Color(0xFF90A4AE), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )); // AnnotatedRegion + Scaffold
  }
}

/// --- Static / helper data builders ---------------------------------------

List<InfoCardData> _buildHeroCards({required VoidCallback onTapAttendance}) {
  return [
    InfoCardData(
      title: 'Mark your attendance',
      subtitle: "Don't forget to clock in today.",
      imageUrl: 'assets/images/home_hero_homework.png',
      ctaLabel: 'Clock In',
      backgroundColor: const Color(0xFFE1F5FE),
      onTap: onTapAttendance,
    ),
    InfoCardData(
      title: 'View attendance history',
      subtitle: 'Track your present and absent days.',
      imageUrl: 'assets/images/home_hero_live.png',
      ctaLabel: 'View Now',
      backgroundColor: const Color(0xFFFDE1E9),
      onTap: onTapAttendance,
    ),
  ];
}

void _comingSoon(BuildContext context, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label — coming soon')),
  );
}

List<QuickLinkItem> _buildQuickLinks({
  required BuildContext context,
  required VoidCallback onTapAttendance,
}) {
  return [
    QuickLinkItem(
      icon: Icons.event_available_outlined,
      label: 'Attendance',
      backgroundColor: const Color(0xFFE8F2FF),
      iconColor: const Color(0xFF4A7CFF),
      onTap: onTapAttendance,
    ),
    QuickLinkItem(
      icon: Icons.description_outlined,
      label: 'Exam',
      backgroundColor: const Color(0xFFF5EBFF),
      iconColor: const Color(0xFF9B51E0),
      onTap: () => _comingSoon(context, 'Exam'),
    ),
    QuickLinkItem(
      icon: Icons.assignment_turned_in_outlined,
      label: 'Leave',
      backgroundColor: const Color(0xFFE6F6F3),
      iconColor: const Color(0xFF2D9CDB),
      onTap: () => _comingSoon(context, 'Leave'),
    ),
    QuickLinkItem(
      icon: Icons.account_balance_outlined,
      label: 'Fees',
      backgroundColor: const Color(0xFFEFF4FF),
      iconColor: const Color(0xFF4A5568),
      onTap: () => _comingSoon(context, 'Fees'),
    ),
    QuickLinkItem(
      icon: Icons.edit_note_outlined,
      label: 'Homework',
      backgroundColor: const Color(0xFFF8F2DC),
      iconColor: const Color(0xFFB7791F),
      onTap: () => _comingSoon(context, 'Homework'),
    ),
    QuickLinkItem(
      icon: Icons.groups_outlined,
      label: 'Community',
      backgroundColor: const Color(0xFFFDE9EC),
      iconColor: const Color(0xFFE65D7B),
      onTap: () => _comingSoon(context, 'Community'),
    ),
    QuickLinkItem(
      icon: Icons.chat_bubble_outline,
      label: 'Message',
      backgroundColor: const Color(0xFFF6EAFE),
      iconColor: const Color(0xFFAA7AE0),
      onTap: () => _comingSoon(context, 'Message'),
    ),
    QuickLinkItem(
      icon: Icons.campaign_outlined,
      label: 'Notice',
      backgroundColor: const Color(0xFFE7F7EC),
      iconColor: const Color(0xFF2F9E44),
      onTap: () => _comingSoon(context, 'Notice'),
    ),
  ];
}

