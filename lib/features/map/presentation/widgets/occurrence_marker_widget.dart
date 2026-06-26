import 'package:flutter/material.dart';
import '../../domain/occurrence_model.dart';

class OccurrenceMarkerWidget extends StatelessWidget {
  final Occurrence? occurrence;
  final int? clusterCount;
  final OccurrenceStatus? clusterStatus;
  final double currentScale;
  final VoidCallback? onTap;

  const OccurrenceMarkerWidget({
    super.key,
    this.occurrence,
    this.clusterCount,
    this.clusterStatus,
    required this.currentScale,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCluster = clusterCount != null;
    final status = isCluster
        ? (clusterStatus ?? OccurrenceStatus.resolved)
        : (occurrence?.status ?? OccurrenceStatus.pending);

    // Resolve color based on status
    final Color statusColor;
    switch (status) {
      case OccurrenceStatus.critical:
        statusColor = const Color(0xFFE53935); // Red
        break;
      case OccurrenceStatus.pending:
        statusColor = const Color(0xFFFB8C00); // Orange
        break;
      case OccurrenceStatus.resolved:
        statusColor = const Color(0xFF43A047); // Green
        break;
    }

    if (isCluster) {
      // Clustered Marker: Solid color with number
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Center(
            child: Text(
              '$clusterCount',
              style: const TextStyle(
                fontFamily: 'Geist',
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    } else {
      // Individual Marker: White circle, colored border, minimalist trash bag inside
      return GestureDetector(
        onTap: onTap ?? () {
          // Fallback if no parent action is set
          final occ = occurrence;
          if (occ != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${occ.title}: ${occ.description}',
                  style: const TextStyle(fontFamily: 'Geist'),
                ),
                backgroundColor: const Color(0xFF01403A),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: statusColor, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: CustomPaint(
              painter: TrashBagPainter(color: statusColor),
            ),
          ),
        ),
      );
    }
  }
}

class TrashBagPainter extends CustomPainter {
  final Color color;

  TrashBagPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path();
    
    // Start at top-middle neck
    path.moveTo(size.width * 0.42, size.height * 0.18);
    
    // Draw the knot/tied neck
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.08,
      size.width * 0.58,
      size.height * 0.18,
    );
    path.lineTo(size.width * 0.72, size.height * 0.26);
    
    // Draw the bag body
    path.cubicTo(
      size.width * 0.95, size.height * 0.42,
      size.width * 0.92, size.height * 0.88,
      size.width * 0.5, size.height * 0.94,
    );
    path.cubicTo(
      size.width * 0.08, size.height * 0.88,
      size.width * 0.05, size.height * 0.42,
      size.width * 0.28, size.height * 0.26,
    );
    path.close();

    canvas.drawPath(path, paint);

    // Draw tie string
    final tiePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.42, size.height * 0.24),
      Offset(size.width * 0.58, size.height * 0.24),
      tiePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
