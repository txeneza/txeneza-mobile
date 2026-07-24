import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

      var currentUser = Supabase.instance.client.auth.currentUser;
      var currentSession = Supabase.instance.client.auth.currentSession;
      final isLoggedInPref = prefs.getBool('is_logged_in') ?? false;

      // Se o SharedPreferences diz que o utilizador está logado mas o Supabase
      // ainda está nulo (tempo de carregamento assíncrono do SDK), esperamos 300ms.
      if ((currentUser == null && currentSession == null) && isLoggedInPref) {
        await Future.delayed(const Duration(milliseconds: 300));
        currentUser = Supabase.instance.client.auth.currentUser;
        currentSession = Supabase.instance.client.auth.currentSession;
      }

      final bool hasUserSession = currentUser != null || currentSession != null;

      // Mantém a sincronização da flag do SharedPreferences
      await prefs.setBool('is_logged_in', hasUserSession);

      if (!hasUserSession) return AppRoutes.login;

      bool needsCompletion = false;

      // Só validamos a necessidade de completar perfil online. Offline avança direto
      // para a home para evitar travar o ecrã de splash em timeouts infinitos.
      final connectivityResults = await Connectivity().checkConnectivity();
      final hasNetwork = connectivityResults.any((r) => r != ConnectivityResult.none);

      if (hasNetwork) {
        try {
          needsCompletion = await ProfileCompletionService()
              .needsCompletion()
              .timeout(
                const Duration(milliseconds: 1500),
                onTimeout: () => false,
              );
        } catch (_) {
          needsCompletion = false;
        }
      }

      // Garante uma exibição mínima do Splash de 1.5s para transição suave
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < const Duration(milliseconds: 1500)) {
        await Future.delayed(const Duration(milliseconds: 1500) - elapsed);
      }

      return needsCompletion ? AppRoutes.completeProfile : AppRoutes.home;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = Supabase.instance.client.auth.currentUser;
      final currentSession = Supabase.instance.client.auth.currentSession;
      final bool hasUserSession = currentUser != null || currentSession != null;

      await prefs.setBool('is_logged_in', hasUserSession);
      return hasUserSession ? AppRoutes.home : AppRoutes.login;
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
