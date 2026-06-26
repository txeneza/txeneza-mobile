import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/theme_controller/theme_provider.dart';
import 'core/theme/theme_data/light_theme.dart';
import 'core/theme/theme_data/dark_theme.dart';
import 'core/theme/colors/app_colors.dart';

import 'core/config/routes/app_routes.dart';
import 'core/config/routes/app_router.dart';

final themeProvider = ThemeProvider();

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final Future<String> _initialRouteFuture;

  @override
  void initState() {
    super.initState();
    _initialRouteFuture = _getInitialRoute();
  }

  Future<String> _getInitialRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('is_first_time') ?? true;
      return isFirstTime ? AppRoutes.onboarding : AppRoutes.home;
    } catch (e) {
      return AppRoutes.onboarding;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return FutureBuilder<String>(
          future: _initialRouteFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return MaterialApp(
                key: const ValueKey('loading'),
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode: themeProvider.themeMode,
                home: const Scaffold(
                  backgroundColor: AppColors.forestGreen,
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.limeGreen,
                    ),
                  ),
                ),
              );
            }

            return MaterialApp(
              key: const ValueKey('main'),
              title: 'Txeneza App',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeProvider.themeMode,
              initialRoute: snapshot.data ?? AppRoutes.onboarding,
              onGenerateRoute: AppRouter.onGenerateRoute,
            );
          },
        );
      },
    );
  }
}
