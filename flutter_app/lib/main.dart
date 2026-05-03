import 'package:flutter/material.dart';

import 'api/client.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'widgets/glass.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  await api.restore();
  runApp(GravityApp(api: api));
}

class GravityApp extends StatelessWidget {
  final ApiClient api;
  const GravityApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accentA,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.accentA,
      surface: const Color(0xFF120B26),
    );

    return MaterialApp(
      title: 'Gravity',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: AppColors.bg1,
        textTheme: Typography.whiteMountainView.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0x33000000),
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.accentA.withValues(alpha: 0.30),
          labelTextStyle: WidgetStateProperty.all(
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          iconTheme: WidgetStateProperty.all(
              const IconThemeData(color: Colors.white)),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1F1638),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: api.isLoggedIn ? HomeShell(api: api) : LoginScreen(api: api),
    );
  }
}
