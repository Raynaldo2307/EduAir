// lib/src/features/shell/student_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/student/home/student_home_page.dart';
import 'package:edu_air/src/features/settings/settings_page.dart';
import 'package:edu_air/src/features/attendance/presentation/student/student_attendance_page.dart';
import 'package:edu_air/src/features/messaging/presentation/student/student_messages_page.dart';

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

    // 2 → Messages
    const StudentMessagesPage(),

    // 3 → Settings
    const SettingsPage(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BottomNavigationBar(
      currentIndex: _tabIndex,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.white,
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
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
    );
  }
}
