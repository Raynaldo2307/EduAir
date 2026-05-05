//ok byimport 'package:edu_air/src/core/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_air/src/features/settings/settings_page.dart';
//import 'package:edu_air/src/features/teacher/student_info_page.dart';
import 'package:edu_air/src/features/admin/home/admin_home_screen.dart';

import 'package:edu_air/src/core/app_theme.dart';

import 'package:edu_air/src/features/admin/students/admin_student_list_page.dart';
import 'package:edu_air/src/features/admin/staff/admin_staff_list_page.dart';
import 'package:edu_air/src/features/admin/attendance/admin_attendance_page.dart';
//import'package:edu_air/src/features/teacher/attendance/teacher_attendance_page.dart';


class AdminResponsiveShell extends ConsumerStatefulWidget {
  const AdminResponsiveShell({super.key});


  @override
  ConsumerState<AdminResponsiveShell> createState() => _AdminResponsiveShellState();

}

class _AdminResponsiveShellState extends ConsumerState<AdminResponsiveShell> {
 int _currentIndex = 0 ;


 //. Alll ow all the admin. to. select cattegoris from. the sidebar
  void _onSelectTab(int index) {
    setState(() {
      _currentIndex = index; 
    });
  }

@override 
Widget build(BuildContext context ){
 // final user = ref.watch(userProvider);
 
    final pages =  
         <Widget>[
            AdminHomeScreen(onSelectTab: _onSelectTab),
            AdminStudentListPage(onBackToHome: () => _onSelectTab(0)),
            AdminStaffListPage(onBackToHome: () => _onSelectTab(0)),
            AdminAttendancePage(onBackToHome: () => _onSelectTab(0)),
            const SettingsPage(),
          ];
    
          

 
 //final screenWidth = MediaQuery.of(context).size.width;
 //final isWide = screenWidth >= 600;

 final navItems = const [
  BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label : 'Home'),
  BottomNavigationBarItem(icon: Icon(Icons.people_outlined), label : 'Students'),
  BottomNavigationBarItem(icon: Icon(Icons.badge_outlined), label : 'Staff'),
  BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), label : 'Attendance'),
  BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label : 'Settings'),


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