// lib/src/features/shell/student_shell.dart

import 'package:edu_air/src/features/student/proflie/student_profile.dart';
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
  /// Which tab is currently selected in the bottom navigation bar.
  int _currentIndex = 0;

  /// Pages for each tab.
  ///
  /// The order **must match** the order of the [BottomNavigationBarItem]s:
  /// 0 → Home
  /// 1 → Calendar
  /// 2 → Messages
  /// 3 → Profile
  late final List<Widget> _pages = [
    const StudentHomePage(),
    const _PlaceholderPage(
      title: 'Calendar',
      icon: Icons.calendar_today_outlined,
    ),
    const _PlaceholderPage(title: 'Messages', icon: Icons.chat_bubble_outline),
    const StudentProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  /// Bottom navigation bar for switching between student tabs.
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.grey,
      backgroundColor: AppTheme.white,
      type: BottomNavigationBarType.fixed,
      onTap: (index) => setState(() => _currentIndex = index),
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
