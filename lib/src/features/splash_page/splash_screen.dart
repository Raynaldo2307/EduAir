import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/core/app_providers.dart';

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
    // Read our services from Riverpod.
    await Future.delayed(const Duration(seconds: 3));

    //Ask the startup provider which route we should go to 
    final targetRoute = await ref.read(startupRouteProvider.future);

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, targetRoute);
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
                .fadeIn(duration: 1200.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 1200.ms,
                  curve: Curves.easeOut,
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
