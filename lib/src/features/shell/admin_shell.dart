import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_air/src/features/settings/settings_page.dart';
import 'package:edu_air/src/features/admin/home/admin_home_screen.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/admin/students/admin_student_list_page.dart';
import 'package:edu_air/src/features/admin/staff/admin_staff_list_page.dart';
import 'package:edu_air/src/features/admin/attendance/admin_attendance_page.dart';

class AdminResponsiveShell extends ConsumerStatefulWidget {
  const AdminResponsiveShell({super.key});

  @override
  ConsumerState<AdminResponsiveShell> createState() =>
      _AdminResponsiveShellState();
}

class _AdminResponsiveShellState extends ConsumerState<AdminResponsiveShell> {
  int _currentIndex = 0;

  void _onSelectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      AdminHomeScreen(onSelectTab: _onSelectTab),
      AdminStudentListPage(onBackToHome: () => _onSelectTab(0)),
      AdminStaffListPage(onBackToHome: () => _onSelectTab(0)),
      AdminAttendancePage(onBackToHome: () => _onSelectTab(0)),
      const SettingsPage(),
    ];

    final navItems = const [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
      BottomNavigationBarItem(
        icon: Icon(Icons.people_outlined),
        label: 'Students',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.badge_outlined), label: 'Staff'),
      BottomNavigationBarItem(
        icon: Icon(Icons.fact_check_outlined),
        label: 'Attendance',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        label: 'Settings',
      ),
    ];

    final safeIndex = _currentIndex < navItems.length ? _currentIndex : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          // ── Desktop / tablet layout ──────────────────────────────
          return Row(
            children: [
              Container(
                width: 220,
                color: const Color(0xFF1A2B4A),
                child : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
              
                  children: [
                    // nav items at top
                    const Text(
                      'EduAir',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Admin Portal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                        letterSpacing: -0.5,
                      ),
                    ),
                  
                  const SizedBox(height: 8),
                  const Text (
                    'ACADEMICS & STUDENTS',
                    style: TextStyle(
                      fontSize : 10 , 
                      fontWeight: FontWeight.bold,
                      color : Colors.white38,
                      letterSpacing: 1.2,
                    ),
                  ),
                  
               // the Academics  and student section header

               const SizedBox(height: 6),
   _NavItems(icon: Icons.dashboard_outlined, label: 'Dashboard', isActive: safeIndex == 0 , onTap: () => _onSelectTab(0)),
    const SizedBox(height: 6),
    _NavItems(icon: Icons.group_outlined, label: 'Students', isActive: safeIndex == 1,  onTap: () => _onSelectTab(1)),
    const SizedBox(height: 6),
    _NavItems(icon: Icons.school_outlined, label: 'Classes & Subjects', isActive:  false,  onTap: () {}),
    const SizedBox(height: 6),
    _NavItems(icon: Icons.calendar_month_outlined, label: 'TimeTable', isActive: false,  onTap: () {}),

         const SizedBox(height: 8),
                  const Text (
                    'ATTENDANCE',
                    style: TextStyle(
                      fontSize : 10 , 
                      fontWeight: FontWeight.bold,
                      color : Colors.white38,
                      letterSpacing: 1.2,
                    ),
                  ),
                const SizedBox(height: 6),
   _NavItems(icon: Icons.fact_check_outlined, label: 'Attendance & Overview', isActive: safeIndex == 4 , onTap: () => _onSelectTab(4)),
    const SizedBox(height: 6),
    _NavItems(icon: Icons.schedule_outlined, label: 'Clock-in Records', isActive: false,  onTap: () {}),
    const SizedBox(height: 6),
    _NavItems(icon: Icons.analytics_outlined, label: 'Reports / SF4', isActive:  false,  onTap: () {}),

     const SizedBox(height: 8),
                  const Text (
                    'STAFF',
                    style: TextStyle(
                      fontSize : 10 , 
                      fontWeight: FontWeight.bold,
                      color : Colors.white38,
                      letterSpacing: 1.2,
                    ),
                  ),
                const SizedBox(height: 6),
   _NavItems(icon: Icons.badge_outlined, label: 'Staff List ', isActive: safeIndex == 3 , onTap: () => _onSelectTab(3)),
    const SizedBox(height: 6),
    _NavItems(icon: Icons.how_to_reg_outlined, label: 'Staff Attendance', isActive: false,  onTap: () {}),
   

 const SizedBox(height: 8),
                  const Text (
                    'COMMUNICATION',
                    style: TextStyle(
                      fontSize : 10 , 
                      fontWeight: FontWeight.bold,
                      color : Colors.white38,
                      letterSpacing: 1.2,
                    ),
                  ),
                const SizedBox(height: 6),
   _NavItems(icon: Icons.campaign_outlined, label: 'Notice  Board', isActive: false , onTap: () {}),
    const SizedBox(height: 6),
    _NavItems(icon: Icons.notifications_outlined, label: 'Notification', isActive:  false,  onTap: () {}),
     const SizedBox(height: 8),
                  const Text (
                    'SYSTEM CONTROL',
                    style: TextStyle(
                      fontSize : 10 , 
                      fontWeight: FontWeight.bold,
                      color : Colors.white38,
                      letterSpacing: 1.2,
                    ),
                  ),
                const SizedBox(height: 6),
   _NavItems(icon: Icons.history_edu_outlined, label: 'Audit & Log', isActive: false, onTap: () {}),
    const SizedBox(height: 6),
    _NavItems(icon: Icons.settings_outlined, label: 'School Settings', isActive:  false,  onTap: () {}),
    

 const SizedBox(height: 8),
                  const Text (
                    'SUPPORT',
                    style: TextStyle(
                      fontSize : 10 , 
                      fontWeight: FontWeight.bold,
                      color : Colors.white38,
                      letterSpacing: 1.2,
                    ),
                  ),
                const SizedBox(height: 6),
   _NavItems(icon: Icons.history_edu_outlined, label: 'Help & FAQ', isActive: false, onTap: () {}),
                  ],

                
                
                
                
                  )
                ),

                ),
              

              
              Expanded(
                child: IndexedStack(index: safeIndex, children: pages),
              ),
            ],
          );
        }

        // ── Mobile layout ────────────────────────────────────────
        return Scaffold(
          body: IndexedStack(index: safeIndex, children: pages),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: safeIndex,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBackground
                : AppTheme.white,
            type: BottomNavigationBarType.fixed,
            onTap: (index) => setState(() => _currentIndex = index),
            items: navItems,
          ),
        );
      },
    );
  }
}

class _NavItems extends StatelessWidget {
  const _NavItems({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F8EF7) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.white, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
