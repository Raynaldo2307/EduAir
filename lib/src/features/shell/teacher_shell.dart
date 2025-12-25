// lib/src/features/shell/teacher_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/teacher/home/teacher_home_screen.dart';
import 'package:edu_air/src/features/teacher/profile/teacher_profile_page.dart';
/// TeacherShell
/// ------------
/// Root container for the **teacher experience** after login + role selection.
///
/// Responsibilities:
/// - Owns the bottom navigation bar for teacher tabs
///   (Home, Calendar, Messages, Profile).
/// - Tracks the currently selected tab via `_currentIndex`.
/// - Shows the correct page for each tab using an `IndexedStack`.
/// - Keeps each tab's state alive while switching tabs.
///
/// Non-responsibilities:
/// - Does NOT implement the actual features (calendar, messages, profile).
/// - Does NOT talk directly to Firebase or services.
///   Each feature has its own screen (e.g. `TeacherHomeScreen`).
class TeacherShell extends ConsumerStatefulWidget {
  const TeacherShell({super.key});

  @override
  ConsumerState<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends ConsumerState<TeacherShell> {
  /// Which tab is currently selected in the bottom navigation bar.
  int _currentIndex = 0;

  /// Pages for each tab.
  ///
  /// The order **must match** the order of the `BottomNavigationBarItem`s:
  /// 0 → Home
  /// 1 → Calendar
  /// 2 → Messages
  /// 3 → Profile
  late final List<Widget> _pages = [
    const TeacherHomeScreen(),
    const _PlaceholderPage(
      title: 'Calendar',
      icon: Icons.calendar_today_outlined,
    ),
    const _PlaceholderPage(title: 'Messages', icon: Icons.chat_bubble_outline),
    const TeacherProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody(), bottomNavigationBar: _buildBottomNav());
  }

  /// Main content area. Uses [IndexedStack] so each tab keeps its state
  /// while you switch between tabs.
  Widget _buildBody() {
    return IndexedStack(index: _currentIndex, children: _pages);
  }

  /// Bottom navigation bar for switching between teacher tabs.
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.grey,
      backgroundColor: AppTheme.white,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
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
///
/// When you build the real Calendar / Messages / Profile screens,
/// you’ll replace the `_PlaceholderPage` entries in `_pages` with your real widgets.
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
