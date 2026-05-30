import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/features/admin/analytics/admin_analytics_screen.dart';
import 'package:edu_air/src/features/admin/attendance/admin_attendance_page.dart';
import 'package:edu_air/src/features/admin/audit/admin_audit_log_screen.dart';
import 'package:edu_air/src/features/admin/classes/admin_classes_screen.dart';
import 'package:edu_air/src/features/admin/clockin/admin_clockin_records_screen.dart';
import 'package:edu_air/src/features/admin/home/admin_home_screen.dart';
import 'package:edu_air/src/features/admin/staff/admin_staff_list_page.dart';
import 'package:edu_air/src/features/admin/staff_attendance/admin_staff_attendance_screen.dart';
import 'package:edu_air/src/features/admin/students/admin_student_list_page.dart';
import 'package:edu_air/src/features/notices/admin_notice_board_screen.dart';
import 'package:edu_air/src/features/settings/settings_page.dart';

class AdminResponsiveShell extends ConsumerStatefulWidget {
  const AdminResponsiveShell({super.key});

  @override
  ConsumerState<AdminResponsiveShell> createState() =>
      _AdminResponsiveShellState();
}

class _AdminResponsiveShellState extends ConsumerState<AdminResponsiveShell> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onSelectTab(int index) => setState(() => _currentIndex = index);

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final tokenStorage = ref.read(tokenStorageProvider);
    await tokenStorage.delete();
    ref.read(userProvider.notifier).state = null;
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    const navItems = [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined),       label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined),  label: 'Analytics'),
      BottomNavigationBarItem(icon: Icon(Icons.people_outlined),     label: 'Students'),
      BottomNavigationBarItem(icon: Icon(Icons.badge_outlined),      label: 'Staff'),
      BottomNavigationBarItem(icon: Icon(Icons.settings_outlined),   label: 'Settings'),
    ];

    // Clamp to bottom-nav range so mobile bar never shows an invalid index.
    final safeIndex = _currentIndex < navItems.length ? _currentIndex : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        // Build pages here so desktop can omit back callbacks.
        final pages = <Widget>[
          // 0 — Dashboard
          AdminHomeScreen(
            onSelectTab: _onSelectTab,
            onOpenDrawer: isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
            onViewAuditLog: isDesktop ? () => _onSelectTab(6) : null,
          ),
          // 1 — Analytics
          AdminAnalyticsPage(
            onBackToHome: isDesktop ? null : () => _onSelectTab(0),
            onOpenDrawer: isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
          ),
          // 2 — Students
          AdminStudentListPage(onBackToHome: isDesktop ? null : () => _onSelectTab(0)),
          // 3 — Staff
          AdminStaffListPage(onBackToHome: isDesktop ? null : () => _onSelectTab(0)),
          // 4 — Settings
          const SettingsPage(),
          // 5 — Attendance
          AdminAttendancePage(onBackToHome: isDesktop ? null : () => _onSelectTab(0)),
          // 6 — Audit & Logs (desktop sidebar only)
          const AdminAuditLogScreen(),
          // 7 — Clock-in Records
          AdminClockinRecordsScreen(onBackToHome: isDesktop ? null : () => _onSelectTab(0)),
          // 8 — Classes & Subjects
          AdminClassesScreen(onBackToHome: isDesktop ? null : () => _onSelectTab(0)),
          // 9 — Staff Attendance
          AdminStaffAttendanceScreen(onBackToHome: isDesktop ? null : () => _onSelectTab(0)),
          // 10 — Notice Board
          AdminNoticeBoardScreen(onBackToHome: isDesktop ? null : () => _onSelectTab(0)),
        ];

        if (isDesktop) {
          // ── Desktop / tablet layout ──────────────────────────────
          return Scaffold(
            body: Row(
              children: [
                Container(
                  width: 260,
                  height: double.infinity,
                  color: const Color(0xFF1A2B4A),
                  child: Column(
                    children: [
                      // ── Logo ──────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EduAir',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Text(
                              'Admin Portal',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.1),
                              height: 1,
                            ),
                          ],
                        ),
                      ),
                      // ── Nav ───────────────────────────────────────────
                      Expanded(
                        child: ScrollbarTheme(
                          data: ScrollbarThemeData(
                            thumbColor: WidgetStateProperty.all(
                              Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Scrollbar(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _NavSection(
                                    label: 'ACADEMICS & STUDENTS',
                                    initiallyExpanded: true,
                                    children: [
                                      _NavItems(
                                        icon: Icons.dashboard_outlined,
                                        label: 'Dashboard',
                                        isActive: _currentIndex == 0,
                                        onTap: () => _onSelectTab(0),
                                      ),
                                      _NavItems(
                                        icon: Icons.group_outlined,
                                        label: 'Students',
                                        isActive: _currentIndex == 2,
                                        onTap: () => _onSelectTab(2),
                                      ),
                                      _NavItems(
                                        icon: Icons.school_outlined,
                                        label: 'Classes',
                                        isActive: _currentIndex == 8,
                                        onTap: () => _onSelectTab(8),
                                      ),
                                      _NavItems(
                                        icon: Icons.calendar_month_outlined,
                                        label: 'Timetable',
                                        isActive: false,
                                        onTap: () {},
                                      ),
                                    ],
                                  ),
                                  _NavSection(
                                    label: 'ATTENDANCE',
                                    initiallyExpanded: true,
                                    children: [
                                      _NavItems(
                                        icon: Icons.fact_check_outlined,
                                        label: 'Attendance & Overview',
                                        isActive: _currentIndex == 5,
                                        onTap: () => _onSelectTab(5),
                                      ),
                                      _NavItems(
                                        icon: Icons.schedule_outlined,
                                        label: 'Clock-in Records',
                                        isActive: _currentIndex == 7,
                                        onTap: () => _onSelectTab(7),
                                      ),
                                      _NavItems(
                                        icon: Icons.analytics_outlined,
                                        label: 'Analytics',
                                        isActive: _currentIndex == 1,
                                        onTap: () => _onSelectTab(1),
                                      ),
                                    ],
                                  ),
                                  _NavSection(
                                    label: 'STAFF',
                                    initiallyExpanded: true,
                                    children: [
                                      _NavItems(
                                        icon: Icons.badge_outlined,
                                        label: 'Staff List',
                                        isActive: _currentIndex == 3,
                                        onTap: () => _onSelectTab(3),
                                      ),
                                      _NavItems(
                                        icon: Icons.how_to_reg_outlined,
                                        label: 'Staff Attendance',
                                        isActive: _currentIndex == 9,
                                        onTap: () => _onSelectTab(9),
                                      ),
                                    ],
                                  ),
                                  _NavSection(
                                    label: 'COMMUNICATION',
                                    initiallyExpanded: false,
                                    children: [
                                      _NavItems(
                                        icon: Icons.campaign_outlined,
                                        label: 'Notice Board',
                                        isActive: _currentIndex == 10,
                                        onTap: () => _onSelectTab(10),
                                      ),
                                      _NavItems(
                                        icon: Icons.notifications_outlined,
                                        label: 'Notifications',
                                        isActive: false,
                                        onTap: () {},
                                      ),
                                    ],
                                  ),
                                  _NavSection(
                                    label: 'SYSTEM CONTROL',
                                    initiallyExpanded: false,
                                    children: [
                                      _NavItems(
                                        icon: Icons.history_edu_outlined,
                                        label: 'Audit & Logs',
                                        isActive: _currentIndex == 6,
                                        onTap: () => _onSelectTab(6),
                                      ),
                                      _NavItems(
                                        icon: Icons.settings_outlined,
                                        label: 'School Settings',
                                        isActive: _currentIndex == 4,
                                        onTap: () => _onSelectTab(4),
                                      ),
                                    ],
                                  ),
                                  _NavSection(
                                    label: 'SUPPORT',
                                    initiallyExpanded: false,
                                    children: [
                                      _NavItems(
                                        icon: Icons.help_outline,
                                        label: 'Help & FAQ',
                                        isActive: false,
                                        onTap: () {},
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ── Logout ────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                        child: Column(
                          children: [
                            Divider(
                              color: Colors.white.withValues(alpha: 0.1),
                              height: 1,
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _logout,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.logout_rounded,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Logout',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: IndexedStack(index: _currentIndex, children: pages),
                ),
              ],
            ),
          );
        }

        // ── Mobile layout ────────────────────────────────────────
        return Scaffold(
          key: _scaffoldKey,

          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFF1A2B4A)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Text(
                        'EduAir',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Admin Portal',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.fact_check_outlined),
                  title: const Text('Attendance'),
                  onTap: () {
                    Navigator.pop(context);
                    _onSelectTab(5);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Clock-in Records'),
                  onTap: () {
                    Navigator.pop(context);
                    _onSelectTab(7);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.how_to_reg_outlined),
                  title: const Text('Staff Attendance'),
                  onTap: () {
                    Navigator.pop(context);
                    _onSelectTab(9);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.campaign_outlined),
                  title: const Text('Notice Board'),
                  onTap: () {
                    Navigator.pop(context);
                    _onSelectTab(10);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('Reports / SF4'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          body: IndexedStack(index: _currentIndex, children: pages),
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

class _NavSection extends StatelessWidget {
  const _NavSection({
    required this.label,
    required this.children,
    this.initiallyExpanded = true,
  });

  final String label;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Remove the default divider ExpansionTile adds
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        childrenPadding: EdgeInsets.zero,
        iconColor: Colors.white54,
        collapsedIconColor: Colors.white38,
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white54,
            letterSpacing: 1.4,
          ),
        ),
        children: children,
      ),
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
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
