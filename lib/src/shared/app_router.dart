import 'package:flutter/material.dart';

import '../features/splash_page/splash_screen.dart';
import '../features/onboard_page/onboard_screen.dart';
import '../features/auth/sign_in_form.dart';
import '../features/auth/sign_up_form.dart';
import '../features/shell/select_role.dart';
import '../features/shell/student_shell.dart';
import '../features/shell/teacher_shell.dart';
import '../features/shell/select_school.dart'; // exports NoSchoolPage

// 👇 NEW: teacher feature screens
import '../features/teacher/attendance/teacher_attendance_page.dart';
//import '../features/teacher/student_info_page.dart';

// 👇 Admin feature screens
import '../features/admin/students/admin_student_list_page.dart';
import '../features/auth/force_change_password_page.dart';

// Smooth fade transition — used for splash → onboarding and splash → login
PageRouteBuilder<T> _fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 600),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashPage());

      case '/onboarding':
        return _fadeRoute(const OnboardingPage());

      case '/signin':
        return _fadeRoute(const SignInPage());

      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignUpPage());

      // After user signs in but before we know role
      case '/selectRole':
        return MaterialPageRoute(builder: (_) => const SelectRolePage());

      // Account exists but no school assigned — admin must link the account.
      case '/noSchool':
        return MaterialPageRoute(builder: (_) => const NoSchoolPage());

      // Main shells
      case '/studentHome':
        return MaterialPageRoute(builder: (_) => const StudentShell());

      case '/teacherHome':
        return MaterialPageRoute(builder: (_) => const TeacherShell());

      // 👇 NEW: teacher quick-link destinations
      case '/teacherAttendance':
        return MaterialPageRoute(builder: (_) => const TeacherAttendancePage());

      //case '/teacherStudentInfo':
       // return MaterialPageRoute(builder: (_) => const StudentInfoPage());

      case '/forceChangePassword':
        return MaterialPageRoute(builder: (_) => const ForceChangePasswordPage());

      // 👇 Admin/Principal student management
      case '/adminStudents':
        return MaterialPageRoute(builder: (_) => const AdminStudentListPage());

      // 👇 Parent portal — role is known, UI not built yet
      case '/parentHome':
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('EduAir')),
            body: const Center(
              child: Text(
                'Parent portal coming soon.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        );
    }

    // 🔁 Fallback for unknown routes
    return MaterialPageRoute(builder: (_) => const SplashPage());
  }
}
