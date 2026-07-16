import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/icons/app_icons.dart';

/// Profundidade (px) da descida do vértice da parábola no rebordo inferior.
const double _kParabolaDepth = 46.0;

/// Gera o rebordo inferior como uma parábola simétrica y = a·x² (vértice ao
/// centro, a apontar para baixo), amostrada em vários pontos para uma curva
/// suave e matematicamente fiel a uma equação quadrática.
Path _buildHeaderPath(Size size, {int samples = 48}) {
  final path = Path()
    ..moveTo(0, 0)
    ..lineTo(0, size.height - _kParabolaDepth);

  final double baseline = size.height - _kParabolaDepth;
  for (int i = 1; i <= samples; i++) {
    final double t = i / samples; // 0 → 1 ao longo da largura
    final double x = t * size.width;
    final double u = 2 * t - 1; // -1 → 1
    // (1 - u²) = 0 nas bordas e 1 no centro: parábola invertida.
    final double y = baseline + _kParabolaDepth * (1 - u * u);
    path.lineTo(x, y);
  }

  path
    ..lineTo(size.width, 0)
    ..close();
  return path;
}

class ParabolicClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _buildHeaderPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Sombra projetada que acompanha exatamente a curva parabólica do header.
class _ParabolaShadowPainter extends CustomPainter {
  final Color color;
  const _ParabolaShadowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildHeaderPath(size);
    canvas.drawShadow(path, color, 10.0, false);
  }

  @override
  bool shouldRepaint(covariant _ParabolaShadowPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Motivo decorativo: o gráfico de uma equação quadrática (parábola côncava
/// para cima, y = a·x²) traçado como linha de acento com brilho subtil.
class _QuadraticCurvePainter extends CustomPainter {
  final Color color;
  const _QuadraticCurvePainter(this.color);

  Path _curve(Size size) {
    final double cx = size.width / 2;
    final double vertexY = size.height * 0.60; // vértice (mínimo) da parábola
    final double armY = size.height * 0.08; // altura dos braços nas bordas
    final double halfW = size.width / 2;
    final double k = (vertexY - armY) / (halfW * halfW); // coef. quadrático

    final path = Path();
    const int samples = 60;
    for (int i = 0; i <= samples; i++) {
      final double x = (i / samples) * size.width;
      final double dx = x - cx;
      final double y = vertexY - k * dx * dx; // y = vertexY - k·(x-cx)²
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _curve(size);

    // Halo suave.
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Linha nítida da curva.
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _QuadraticCurvePainter oldDelegate) =>
      oldDelegate.color != color;
}

class AuthHeaderWidget extends StatelessWidget {
  final bool showBackButton;

  const AuthHeaderWidget({
    super.key,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    const double height = 210;

    return SizedBox(
      height: height + 14, // margem extra para a sombra respirar
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Sombra que segue a parábola.
          Positioned.fill(
            bottom: 14,
            child: CustomPaint(
              painter: _ParabolaShadowPainter(
                primaryColor.withValues(alpha: 0.45),
              ),
            ),
          ),

          // Header parabólico.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: ParabolicClipper(),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(primaryColor, Colors.white, 0.06) ??
                          primaryColor,
                      primaryColor,
                      Color.lerp(primaryColor, Colors.black, 0.18) ??
                          primaryColor,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Motivo do gráfico da equação quadrática.
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _QuadraticCurvePainter(AppColors.limeGreen),
                      ),
                    ),

                    // Círculos abstratos de fundo para profundidade premium.
                    Positioned(
                      top: -34,
                      right: -34,
                      child: _softCircle(120, 0.06),
                    ),
                    Positioned(
                      bottom: 24,
                      left: -22,
                      child: _softCircle(84, 0.04),
                    ),

                    // Logo central da Txeneza.
                    Center(
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 22.0),
                          child: SvgPicture.asset(
                            AppIcons.logo,
                            height: 54,
                          ),
                        ),
                      ),
                    ),

                    // Botão opcional de voltar (SignUpPage).
                    if (showBackButton)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: SafeArea(
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.18),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.of(context).pop(),
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  LucideIcons.arrowLeft,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _softCircle(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}
