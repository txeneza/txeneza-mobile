import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../features/auth/data/datasources/profile_completion_service.dart';
import '../../../../features/onboarding/presentation/pages/splash_screen.dart';
import 'app_routes.dart';
import '../../../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../../../features/onboarding/presentation/pages/permission.dart';
import '../../../../features/home/presentation/pages/home_screen.dart';
import '../../../../features/chatIA/presentation/pages/chat_ia_screen.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';
import '../../../../features/auth/presentation/pages/signup_page.dart';
import '../../../../features/auth/presentation/pages/complete_profile_page.dart';
import '../../../../features/profile/presentation/pages/sub_pages/change_password_page.dart';
import '../../../../features/profile/presentation/pages/sub_pages/privacy_policy_page.dart';
import '../../../../features/profile/presentation/pages/sub_pages/terms_of_use_page.dart';
import '../../../../features/profile/presentation/pages/sub_pages/help_faq_page.dart';
import '../../../../features/profile/presentation/pages/sub_pages/report_problem_page.dart';
import '../../../../features/profile/presentation/pages/sub_pages/contact_page.dart';
import '../../../../features/home/presentation/pages/my_reports_page.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    // Tratar rotas de redirecionamento do Supabase (deep linking)
    if (routeName == '/' ||
        routeName.startsWith('/?') ||
        routeName.startsWith('txeneza://') ||
        routeName.startsWith('io.txeneza.app://')) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const InitialRouteScreen(),
      );
    }

    switch (routeName) {
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
      case AppRoutes.login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginPage(),
        );
      case AppRoutes.signUp:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SignUpPage(),
        );
      case AppRoutes.completeProfile:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CompleteProfilePage(),
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
      case AppRoutes.chatIA:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ChatIAScreen(),
        );
      case AppRoutes.changePassword:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ChangePasswordPage(),
        );
      case AppRoutes.privacyPolicy:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PrivacyPolicyPage(),
        );
      case AppRoutes.termsOfUse:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TermsOfUsePage(),
        );
      case AppRoutes.helpFaq:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HelpFaqPage(),
        );
      case AppRoutes.reportProblem:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ReportProblemPage(),
        );
      case AppRoutes.contact:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ContactPage(),
        );
      case AppRoutes.myReports:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MyReportsPage(),
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

class InitialRouteScreen extends StatefulWidget {
  const InitialRouteScreen({super.key});

  @override
  State<InitialRouteScreen> createState() => _InitialRouteScreenState();
}

class _InitialRouteScreenState extends State<InitialRouteScreen> {
  @override
  void initState() {
    super.initState();
    _routeUser();
  }

  Future<void> _routeUser() async {
    // Pequeno atraso para dar tempo ao Supabase de processar o deep link
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('is_first_time') ?? true;
      if (!mounted) return;
      if (isFirstTime) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
        return;
      }

      final hasSession = Supabase.instance.client.auth.currentSession != null;
      if (!mounted) return;
      if (!hasSession) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        return;
      }

      final needsCompletion = await ProfileCompletionService().needsCompletion();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        needsCompletion ? AppRoutes.completeProfile : AppRoutes.home,
      );
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
