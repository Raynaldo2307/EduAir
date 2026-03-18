//import 'package:edu_air/src/features/shell/student_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:edu_air/src/shared/app_router.dart';

// Theme + Router
import 'package:edu_air/src/core/app_theme.dart';
import 'package:edu_air/src/core/app_providers.dart';
//import 'package:edu_air/src/features/shell/teacher_shell.dart';
//import 'src/dev/dev_seed_schools.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

// ConsumerWidget so we can watch themeModeProvider
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuilds whenever the user toggles dark/light mode
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'EduAIR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,           // ← this is what makes the switch work
      initialRoute: '/teacher',
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
