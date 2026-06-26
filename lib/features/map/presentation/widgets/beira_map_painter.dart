import 'package:flutter/material.dart';

class BeiraMapPainter extends CustomPainter {
  final bool isHeatmap;

  BeiraMapPainter({required this.isHeatmap});

  @override
  void paint(Canvas canvas, Size size) {
    // Scale coordinates from 1600x1600 coordinate system to physical widget size
    final double scaleX = size.width / 1600.0;
    final double scaleY = size.height / 1600.0;
    final double scale = (scaleX + scaleY) / 2;

    // 1. Draw land background (soft desaturated grey-beige)
    final Paint landPaint = Paint()
      ..color = const Color(0xFFF4F2EB)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, landPaint);

    // 2. Draw Vegetation zones (faded green)
    final Paint vegPaint = Paint()
      ..color = const Color(0xFFD4E5D4)
      ..style = PaintingStyle.fill;

    // Palmeiras Park
    canvas.drawOval(
      Rect.fromLTRB(1050 * scaleX, 650 * scaleY, 1320 * scaleX, 850 * scaleY),
      vegPaint,
    );
    // Munhava swamp/green area
    canvas.drawOval(
      Rect.fromLTRB(300 * scaleX, 350 * scaleY, 650 * scaleX, 550 * scaleY),
      vegPaint,
    );
    // Esturro Park
    canvas.drawOval(
      Rect.fromLTRB(720 * scaleX, 680 * scaleY, 880 * scaleX, 800 * scaleY),
      vegPaint,
    );

    // 3. Draw Ocean/Sea (Oceano Índico) in East and South
    final Path oceanPath = Path();
    oceanPath.moveTo(1600 * scaleX, 350 * scaleY);
    oceanPath.quadraticBezierTo(
      1150 * scaleX, 850 * scaleY,
      850 * scaleX, 1250 * scaleY,
    );
    oceanPath.quadraticBezierTo(
      550 * scaleX, 1450 * scaleY,
      0 * scaleX, 1600 * scaleY,
    );
    oceanPath.lineTo(1600 * scaleX, 1600 * scaleY);
    oceanPath.close();

    final Paint waterPaint = Paint()
      ..color = const Color(0xFF9DB2BD) // Grey-blue canal and sea
      ..style = PaintingStyle.fill;
    canvas.drawPath(oceanPath, waterPaint);

    // 4. Draw Canal de Chiveve (winds through city)
    final Path canalPath = Path();
    canalPath.moveTo(250 * scaleX, 1330 * scaleY); // Port area
    canalPath.cubicTo(
      320 * scaleX, 1150 * scaleY,
      480 * scaleX, 1000 * scaleY,
      500 * scaleX, 850 * scaleY,
    );
    canalPath.cubicTo(
      520 * scaleX, 720 * scaleY,
      420 * scaleX, 680 * scaleY,
      450 * scaleX, 580 * scaleY,
    );

    final Paint canalPaint = Paint()
      ..color = const Color(0xFF9DB2BD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(canalPath, canalPaint);

    // 5. Draw Roads (Off-white roads)
    final Paint roadPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 * scale
      ..strokeCap = StrokeCap.round;

    // N6 (Av de Moçambique)
    final Path roadN6 = Path();
    roadN6.moveTo(100 * scaleX, 100 * scaleY);
    roadN6.lineTo(600 * scaleX, 800 * scaleY);
    canvas.drawPath(roadN6, roadPaint);

    // Av Eduardo Mondlane
    final Path roadMondlane = Path();
    roadMondlane.moveTo(200 * scaleX, 900 * scaleY);
    roadMondlane.lineTo(1200 * scaleX, 900 * scaleY);
    canvas.drawPath(roadMondlane, roadPaint);

    // Av Samora Machel (coastal road)
    final Path roadSamora = Path();
    roadSamora.moveTo(1580 * scaleX, 360 * scaleY);
    roadSamora.quadraticBezierTo(
      1130 * scaleX, 860 * scaleY,
      830 * scaleX, 1260 * scaleY,
    );
    roadSamora.quadraticBezierTo(
      530 * scaleX, 1460 * scaleY,
      10 * scaleX, 1590 * scaleY,
    );
    canvas.drawPath(roadSamora, roadPaint);

    // Av 25 de Setembro
    final Path road25Set = Path();
    road25Set.moveTo(400 * scaleX, 1050 * scaleY);
    road25Set.lineTo(950 * scaleX, 1050 * scaleY);
    canvas.drawPath(road25Set, roadPaint);

    // 6. Draw neighborhood labels
    _drawLabel(canvas, "MUNHAVA", 450 * scaleX, 450 * scaleY, scale);
    _drawLabel(canvas, "MACUTI", 1200 * scaleX, 760 * scaleY, scale);
    _drawLabel(canvas, "ESTURRO", 800 * scaleX, 850 * scaleY, scale);
    _drawLabel(canvas, "PONTA GÊA", 550 * scaleX, 1150 * scaleY, scale);
    _drawLabel(canvas, "PORTO DA BEIRA", 150 * scaleX, 1420 * scaleY, scale);
    _drawLabel(canvas, "OCEANO ÍNDICO", 1250 * scaleX, 1250 * scaleY, scale, isOcean: true);

    // 7. Draw Heatmap layers if active
    if (isHeatmap) {
      _drawHeatBlob(canvas, Offset(500 * scaleX, 590 * scaleY), 180 * scale, const Color(0xFFFF3B30)); // Alta
      _drawHeatBlob(canvas, Offset(675 * scaleX, 975 * scaleY), 150 * scale, const Color(0xFFFF9500)); // Média
      _drawHeatBlob(canvas, Offset(1110 * scaleX, 890 * scaleY), 130 * scale, const Color(0xFFFFCC00)); // Baixa
    }
  }

  void _drawLabel(Canvas canvas, String text, double x, double y, double scale, {bool isOcean = false}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: (isOcean ? 11 : 9) * scale,
          fontWeight: FontWeight.bold,
          color: isOcean ? const Color(0x70FFFFFF) : const Color(0x6001403A),
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  void _drawHeatBlob(Canvas canvas, Offset center, double radius, Color color) {
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final Gradient gradient = RadialGradient(
      colors: [
        color.withValues(alpha: 0.65),
        color.withValues(alpha: 0.25),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant BeiraMapPainter oldDelegate) {
    return oldDelegate.isHeatmap != isHeatmap;
  }
}
