import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_air/src/core/app_theme.dart';
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

  /// Allow children to switch tabs (0 = Home, 1 = Student Info, 2 = Messages, 3 = Profile).
  void _onSelectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    
    
    final pages = 
         <Widget>[
            TeacherHomeScreen(onSelectTab: _onSelectTab),
            StudentInfoPage(onBackToHome: () => _onSelectTab(0)),
            const TeacherAttendancePage(),
            const SettingsPage(),
          ];

    final navItems = 
         const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              label: 'Students',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fact_check_outlined),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: 'Settings',
            ),
          ];

    // Clamp index synchronously so the assertion never fires, regardless of
    // when userProvider changes relative to this build frame.
    final safeIndex = _currentIndex < navItems.length ? _currentIndex : 0;

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: pages),
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


