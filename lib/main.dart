import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // FCM init non-blocking — error tidak menghentikan app
  FCMService().initialize().catchError((e) => debugPrint('FCM: $e'));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AssignmentProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => ViolationProvider()),
        ChangeNotifierProvider(create: (_) => CounselingProvider()),
      ],
      child: const EduTechApp(),
    ),
  );
}

class EduTechApp extends StatelessWidget {
  const EduTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduTech SMK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRouter.generateRoute,
      home: const LoginPage(),
    );
  }
}
