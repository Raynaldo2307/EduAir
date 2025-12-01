// lib/src/features/shell/student_shell.dart
//StudentShell
/// --------------
/// Role:
/// - Root container for the student experience after login + role selection.
/// - Shown after `SelectRolePage` when the user chooses the `student` role.
///
/// Responsibilities:
/// - Owns the bottom navigation bar for student tabs (Home, Calendar, Messages, Profile).
/// - Tracks the currently selected tab via `_currentIndex`.
/// - Shows the correct page for each tab using an `IndexedStack`.
/// - Keeps each tab's state alive while switching (thanks to `IndexedStack`).
///
/// Non-responsibilities:
/// - Does NOT contain feature logic for calendar, messages, or profile.
/// - Does NOT talk directly to Firebase or services.
/// - Each feature gets its own screen (e.g. `StudentHomePage`, `StudentCalendarPage`, etc.).
///
/// Implementation notes:
/// - `_pages` is a `List<Widget>` that holds the tab pages, in the same order as the bottom nav items.
/// - `late final` ensures `_pages` is created once per state instance and never reassigned.
/// - `_PlaceholderPage` is a temporary "Coming soon" page until those features are implemented.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/student/home/student_home_page.dart';

class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  int _currentIndex = 0;


   // These pages only need to be created once
  late final List<Widget> _pages = [
    const StudentHomePage(),
    const _PlaceholderPage(
      title: 'Calendar',
      icon: Icons.calendar_today_outlined,
    ),
    const _PlaceholderPage(
      title: 'Messages',
      icon: Icons.chat_bubble_outline,
    ),
    const _PlaceholderPage(
      title: 'Profile',
      icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {

    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.grey,
        backgroundColor: AppTheme.white,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
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
      ),
    );
  }
}

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
