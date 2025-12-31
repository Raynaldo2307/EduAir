// lib/src/features/shell/student_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/student/home/student_home_page.dart';
import 'package:edu_air/src/features/student/proflie/student_profile.dart';
import 'package:edu_air/src/features/attendance/presentation/student/student_attendance_page.dart';

/// Shell for all student-facing tabs:
/// 0 → Home
/// 1 → Calendar / Attendance
/// 2 → Messages
/// 3 → Profile
class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  /// Currently selected bottom-nav tab.
  int _tabIndex = 0;

  /// Helper: jump to the Calendar/Attendance tab.
  void _goToCalendarTab() {
    setState(() {
      _tabIndex = 1;
    });
  }

  /// Pages for each tab.
  ///
  /// Order MUST match [BottomNavigationBarItem]s.
  late final List<Widget> _pages = [
    // 0 → Home: pass a callback so tapping the "Attendance" quick link
    // switches the shell to the Calendar tab instead of pushing a new route.
    StudentHomePage(onTapAttendance: _goToCalendarTab),

    // 1 → Calendar / Attendance
    const StudentAttendancePage(),

    // 2 → Messages (placeholder for now)
    const _PlaceholderPage(title: 'Messages', icon: Icons.chat_bubble_outline),

    // 3 → Profile
    const StudentProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  /// Bottom navigation bar for switching between student tabs.
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _tabIndex,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.grey,
      backgroundColor: AppTheme.white,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        setState(() {
          _tabIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}

/// Temporary "coming soon" placeholder for tabs that are not implemented yet.
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: AppTheme.primaryColor),
          const SizedBox(height: 12),
          Text(
            '$title coming soon',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
