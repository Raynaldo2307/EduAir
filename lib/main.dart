//import 'package:edu_air/src/features/shell/student_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:edu_air/src/shared/app_router.dart';

// Theme + Router
import 'package:edu_air/src/core/app_theme.dart';
//import 'package:edu_air/src/features/shell/teacher_shell.dart';
//import 'src/dev/dev_seed_schools.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduAIR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // ✅ Routing Starts Here
      initialRoute: '/teacher',
      onGenerateRoute: AppRouter.generateRoute,
      // home: const StudentShell(),
    );
  }
}
