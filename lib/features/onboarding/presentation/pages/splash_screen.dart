import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/icons/app_icons.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _contentController;
  late AnimationController _shimmerController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _taglineFade;
  late Animation<double> _bottomFade;

  @override
  void initState() {
    super.initState();

    // Fase 1: Logo aparece com fade + scale suave
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Fase 2: Conteúdo textual entra com ligeiro atraso (cascata)
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.3, 0.85, curve: Curves.easeOut),
      ),
    );

    _bottomFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Shimmer contínuo no indicador de carregamento
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Sequência de animações
    _logoController.forward().then((_) {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF01403A), // forestGreen
              Color(0xFF012E29),
              Color(0xFF011E1B),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isPortrait = constraints.maxHeight > constraints.maxWidth;
              final logoSize = isPortrait
                  ? constraints.maxWidth * 0.32
                  : constraints.maxHeight * 0.28;

              return Stack(
                children: [
                  // Glow radiante subtil atrás do logo
                  Center(
                    child: AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoFade.value * 0.6,
                          child: child,
                        );
                      },
                      child: Container(
                        width: logoSize * 2.2,
                        height: logoSize * 2.2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.limeGreen.withValues(alpha: 0.06),
                              AppColors.limeGreen.withValues(alpha: 0.02),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Conteúdo principal: Logo + Título + Tagline
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo com animação de entrada
                        AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _logoFade.value,
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 30,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/TXENEZA.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Título "TXENEZA" com slide-up
                        AnimatedBuilder(
                          animation: _contentController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _titleFade.value,
                              child: SlideTransition(
                                position: _titleSlide,
                                child: child,
                              ),
                            );
                          },
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 5.0,
                                color: Colors.white,
                              ),
                              children: [
                                TextSpan(text: 'T'),
                                TextSpan(
                                  text: 'X',
                                  style: TextStyle(
                                    color: AppColors.limeGreen,
                                  ),
                                ),
                                TextSpan(text: 'ENEZA'),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Tagline / slogan
                        AnimatedBuilder(
                          animation: _contentController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _taglineFade.value,
                              child: child,
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 1,
                                color: AppColors.limeGreen.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'SANEAMENTO INTELIGENTE',
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2.5,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 16,
                                height: 1,
                                color: AppColors.limeGreen.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Indicador de carregamento minimalista com shimmer
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: isPortrait ? 100 : 50,
                    child: AnimatedBuilder(
                      animation: _contentController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _bottomFade.value,
                          child: child,
                        );
                      },
                      child: Center(
                        child: SizedBox(
                          width: 120,
                          height: 2.5,
                          child: AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, _) {
                              return CustomPaint(
                                painter: _ShimmerBarPainter(
                                  progress: _shimmerController.value,
                                  color: AppColors.limeGreen,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Rodapé enterprise: powered by
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: isPortrait ? 44 : 16,
                    child: AnimatedBuilder(
                      animation: _contentController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _bottomFade.value,
                          child: child,
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                AppIcons.logo,
                                width: 14,
                                height: 14,
                                colorFilter: ColorFilter.mode(
                                  Colors.white.withValues(alpha: 0.3),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Conselho Municipal da Beira',
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.8,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Pinta uma barra de carregamento com efeito shimmer que se desloca.
class _ShimmerBarPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ShimmerBarPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Fundo da barra
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(2),
      ),
      bgPaint,
    );

    // Shimmer em movimento
    final shimmerWidth = size.width * 0.35;
    final left = (size.width + shimmerWidth) * progress - shimmerWidth;
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.7),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(left, 0, shimmerWidth, size.height));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 0, shimmerWidth, size.height),
        const Radius.circular(2),
      ),
      shimmerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ShimmerBarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
