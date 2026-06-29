import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../../../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../../../features/onboarding/presentation/pages/permission.dart';
import '../../../../features/home/presentation/pages/home_screen.dart';
import '../../../../features/chatIA/presentation/pages/chat_ia_screen.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';
import '../../../../features/auth/presentation/pages/signup_page.dart';
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
