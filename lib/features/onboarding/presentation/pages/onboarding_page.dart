import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/config/routes/app_routes.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../../../core/theme/spacing/app_radius.dart';
import '../widgets/onboarding_slide_widget.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _pageController;
  int _currentPage = 0;
  static const int _totalPages = 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _navigateToPermission() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.permission);
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip/Ignorar Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedOpacity(
                    opacity: _currentPage < _totalPages - 1 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: _currentPage >= _totalPages - 1,
                      child: TextButton(
                        onPressed: _navigateToPermission,
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        child: Text(
                          'Ignorar',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView for Onboarding Slides
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                children: [
                  // Screen 1: Welcome
                  const OnboardingSlideWidget(
                    title: 'Ajude a tornar a Beira mais limpa',
                    description: 'Identifique, reporte e acompanhe problemas de resíduos sólidos na sua comunidade através de uma plataforma inteligente e colaborativa.',
                    imagePath: 'assets/images/onboarding_welcome.png',
                    features: [
                      OnboardingFeature(
                        icon: LucideIcons.users,
                        label: 'Comunitário',
                      ),
                      OnboardingFeature(
                        icon: LucideIcons.sparkles,
                        label: 'Inteligente',
                      ),
                    ],
                  ),

                  // Screen 2: Report
                  const OnboardingSlideWidget(
                    title: 'Fotografe e reporte resíduos',
                    description: 'Tire uma foto, indique a localização e envie a denúncia em poucos passos. A Inteligência Artificial ajuda a classificar automaticamente o tipo e a gravidade do problema.',
                    imagePath: 'assets/images/onboarding_report.png',
                    features: [
                      OnboardingFeature(
                        icon: LucideIcons.camera,
                        label: 'Captura de foto',
                      ),
                      OnboardingFeature(
                        icon: LucideIcons.mapPin,
                        label: 'Localização GPS',
                      ),
                      OnboardingFeature(
                        icon: LucideIcons.cpu,
                        label: 'Análise automática',
                      ),
                    ],
                  ),

                  // Screen 3: Offline
                  const OnboardingSlideWidget(
                    title: 'Registe denúncias mesmo offline',
                    description: 'Em áreas com conectividade limitada, as denúncias são armazenadas localmente e enviadas automaticamente quando a internet estiver disponível.',
                    imagePath: 'assets/images/onboarding_offline.png',
                    features: [
                      OnboardingFeature(
                        icon: LucideIcons.wifiOff,
                        label: 'Offline First',
                      ),
                      OnboardingFeature(
                        icon: LucideIcons.refreshCw,
                        label: 'Sincronização automática',
                      ),
                      OnboardingFeature(
                        icon: LucideIcons.map,
                        label: 'Zonas periféricas',
                      ),
                    ],
                  ),

                  // Screen 4: Map & Impact
                  const OnboardingSlideWidget(
                    title: 'Veja problemas resolvidos e impacte a comunidade',
                    description: 'Acompanhe o estado das denúncias, visualize áreas críticas no mapa e consulte evidências da resolução dos problemas reportados.',
                    imagePath: 'assets/images/onboarding_map.png',
                    features: [
                      OnboardingFeature(
                        icon: LucideIcons.map,
                        label: 'Mapa interativo',
                      ),
                      OnboardingFeature(
                        icon: LucideIcons.checkSquare,
                        label: 'Status transparente',
                      ),
                      OnboardingFeature(
                        icon: LucideIcons.shieldCheck,
                        label: 'Prestação de contas',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Navigation Area
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentPage < _totalPages - 1
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Custom Page Indicator Dots
                          Row(
                            children: List.generate(
                              _totalPages,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                height: 8.0,
                                width: _currentPage == index ? 24.0 : 8.0,
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? theme.colorScheme.primary
                                      : (isDark
                                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                          : theme.colorScheme.primary.withValues(alpha: 0.3)),
                                  borderRadius: AppRadius.borderCircular,
                                ),
                              ),
                            ),
                          ),

                          // Next Page Button
                          SizedBox(
                            width: AppSpacing.minTouchTarget + 8,
                            height: AppSpacing.minTouchTarget + 8,
                            child: ElevatedButton(
                              onPressed: _nextPage,
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                                padding: EdgeInsets.zero,
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                              child: const Icon(
                                LucideIcons.arrowRight,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _navigateToPermission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.tertiary, // Accent lime green
                            foregroundColor: theme.colorScheme.onTertiary, // forestGreen for high contrast
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.borderMD,
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Começar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              AppSpacing.horizontalSpaceSM,
                              Icon(
                                LucideIcons.checkCircle,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
