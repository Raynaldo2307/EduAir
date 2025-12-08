import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/core/app_providers.dart';
import 'package:edu_air/src/features/student/home/student_home_page.dart';

import 'package:edu_air/src/features/Teacher/home/teacher_home_screen.dart';

// or student_home_screen.dart etc – use your real file

/// SplashPage is the very first screen of the app.
///
/// Responsibilities:
/// 1. Show the logo + loading indicator.
/// 2. Decide where the user should go next based on auth + profile:
///    - If no user → onboarding.
///    - If user exists but no profile (future) → could go to select role.
///    - If user + profile → go to main area (currently `/home`).
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  Route _slideFromRightRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    // As soon as the widget is created, we start the bootstrap process.
    _bootstrap();
  }

  /// Bootstrap = "start up logic".
  ///
  /// Here we:
  /// - Wait a short time so the user can see the splash.
  /// - Ask Firebase Auth if there is a current user.
  /// - If there is, we load their profile from Firestore.
  /// - Based on that, we decide which route to send them to.
  Future<void> _bootstrap() async {
    // 1) Wait so we can show the splash animation
    await Future.delayed(const Duration(seconds: 2));

    // 2) Ask the startup provider which route we should go to
    final targetRoute = await ref.read(startupRouteProvider.future);

    if (!mounted) return;

    // 3) If we should go to /home, use the custom slide animation
    if (targetRoute == '/studenthome') {
      Navigator.of(context).pushReplacement(
        widget._slideFromRightRoute(
          const StudentHomePage(), // <- your actual home widget here
        ),
      );
    } else if (targetRoute == '/teacherHome'){
     Navigator.of(context).pushReplacement( 
      widget._slideFromRightRoute( 
        const TeacherHomeScreen(),
      ),
     );

     }
     else {
      // 4) For ALL other routes, keep using the global named routes
      Navigator.pushReplacementNamed(context, targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center logo with soft glow + animation.
            Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/eduair_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                .animate()
                // 1) Fade in
                .fadeIn(duration: 600.ms, curve: Curves.easeOutCubic)
                // 2) Zoom in a bit past 1.0 (gives that "pop" feeling)
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1.05, 1.05),
                  duration: 700.ms,
                  curve: Curves.easeOutBack,
                )
                // 3) Then gently settle back to 1.0
                .then() // << continue the same timeline
                .scale(
                  begin: const Offset(1.05, 1.05),
                  end: const Offset(1.05, 1.05),
                  duration: 300.ms,
                  curve: Curves.easeOutCubic,
                ),

            // Loading spinner at the bottom to show we are doing work.
            Positioned(
              bottom: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
