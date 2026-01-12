import 'package:flutter/material.dart';

import '../features/splash_page/splash_screen.dart';
import '../features/onboard_page/onboard_screen.dart';
import '../features/auth/sign_in_form.dart';
import '../features/auth/sign_up_form.dart';
import '../features/shell/select_role.dart';
import '../features/shell/student_shell.dart';
import '../features/shell/teacher_shell.dart';
import '../features/shell/select_school.dart'; // 👈 NEW

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashPage());

      case '/onboarding':
        return MaterialPageRoute(builder: (_) => const OnboardingPage());

      case '/signin':
        return MaterialPageRoute(builder: (_) => const SignInPage());

      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignUpPage());

      // After user signs in but before we know role
      case '/selectRole':
        return MaterialPageRoute(builder: (_) => const SelectRolePage());

      // After role is set but before school is chosen
      case '/selectSchool': // 👈 NEW
        return MaterialPageRoute(builder: (_) => const SelectSchoolPage());

      // Main shells
      case '/studentHome':
        return MaterialPageRoute(builder: (_) => const StudentShell());

      case '/teacherHome':
        return MaterialPageRoute(builder: (_) => const TeacherShell());
    }

    // 🔁 Fallback for unknown routes
    return MaterialPageRoute(builder: (_) => const SplashPage());
  }
}
