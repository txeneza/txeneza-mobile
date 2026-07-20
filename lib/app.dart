import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/theme_controller/theme_provider.dart';
import 'core/theme/theme_data/light_theme.dart';
import 'core/theme/theme_data/dark_theme.dart';

import 'core/config/routes/app_routes.dart';
import 'core/config/routes/app_router.dart';
import 'features/auth/data/datasources/profile_completion_service.dart';
import 'features/onboarding/presentation/pages/splash_screen.dart';

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
    final startTime = DateTime.now();

    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('is_first_time') ?? true;
      if (isFirstTime) {
        return AppRoutes.onboarding;
      }

      final hasSession = Supabase.instance.client.auth.currentSession != null;
      if (!hasSession) return AppRoutes.login;

      // Se o utilizador estiver offline ou a ligacao for lenta, o timeout garante que a app avanca
      final needsCompletion = await ProfileCompletionService()
          .needsCompletion()
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () => false,
          );

      // Garante uma exibicao minima do Splash de 1.5s para transicao suave
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < const Duration(milliseconds: 1500)) {
        await Future.delayed(const Duration(milliseconds: 1500) - elapsed);
      }

      return needsCompletion ? AppRoutes.completeProfile : AppRoutes.home;
    } catch (e) {
      final hasSession = Supabase.instance.client.auth.currentSession != null;
      return hasSession ? AppRoutes.home : AppRoutes.login;
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
                home: const SplashScreen(),
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
