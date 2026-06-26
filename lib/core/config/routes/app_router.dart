import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../../../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../../../features/onboarding/presentation/pages/permission.dart';
import '../../../../features/home/presentation/pages/home_screen.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.onboarding:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OnboardingPage(),
        );
      case AppRoutes.permission:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PermissionPage(),
        );
      case AppRoutes.home:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Nenhuma rota definida para ${settings.name}'),
            ),
          ),
        );
    }
  }
}
