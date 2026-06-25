import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/notices/notice_board_screen.dart';
import 'package:edu_air/src/features/teacher/home/teacher_home_screen.dart';
import 'package:edu_air/src/features/settings/settings_page.dart';
import 'package:edu_air/src/features/teacher/student_info_page.dart';

import 'package:edu_air/src/features/teacher/attendance/teacher_attendance_page.dart';

class TeacherShell extends ConsumerStatefulWidget {
  const TeacherShell({super.key});

  @override
  ConsumerState<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends ConsumerState<TeacherShell> {
  int _currentIndex = 0;

  /// Allow children to switch tabs.
  /// 0 = Home, 1 = Students, 2 = Attendance, 3 = Notices, 4 = Settings.
  void _onSelectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    
    
    const navItems = [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined),        label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.people_outline),       label: 'Students'),
      BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined),  label: 'Attendance'),
      BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined),    label: 'Notices'),
      BottomNavigationBarItem(icon: Icon(Icons.settings_outlined),    label: 'Settings'),
    ];

    final safeIndex = _currentIndex < navItems.length ? _currentIndex : 0;

    Widget currentPage() {
      switch (safeIndex) {
        case 1:  return StudentInfoPage(onBackToHome: () => _onSelectTab(0));
        case 2:  return const TeacherAttendancePage();
        case 3:  return const NoticeBoardScreen();
        case 4:  return const SettingsPage();
        default: return TeacherHomeScreen(onSelectTab: _onSelectTab);
      }
    }

    return Scaffold(
      body: currentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBackground : AppTheme.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: navItems,
      ),
    );
  }
}


