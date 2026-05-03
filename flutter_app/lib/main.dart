import 'package:flutter/material.dart';

import 'api/client.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'theme/theme_controller.dart';
import 'widgets/glass.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  await api.restore();
  final theme = await ThemeController.load();
  runApp(GravityApp(api: api, theme: theme));
}

class GravityApp extends StatelessWidget {
  final ApiClient api;
  final ThemeController theme;
  const GravityApp({super.key, required this.api, required this.theme});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: theme,
      builder: (ctx, _) {
        final scheme = ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        );

        return MaterialApp(
          title: 'Gravity',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: scheme,
            scaffoldBackgroundColor: AppColors.bg1,
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.text,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              centerTitle: false,
              titleTextStyle: const TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            cardTheme: const CardThemeData(
              elevation: 0,
              color: AppColors.surface,
              surfaceTintColor: Colors.transparent,
            ),
            navigationDrawerTheme: NavigationDrawerThemeData(
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.primaryLight,
            ),
            snackBarTheme: const SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.text,
              contentTextStyle: TextStyle(color: Colors.white),
            ),
            dividerColor: AppColors.outline,
          ),
          home: api.isLoggedIn
              ? HomeShell(api: api, theme: theme)
              : LoginScreen(api: api, theme: theme),
        );
      },
    );
  }
}
