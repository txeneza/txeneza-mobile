import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../domain/occurrence_model.dart';

/// Cor associada a cada estado de ocorrência (partilhada com o bottom sheet).
Color occurrenceStatusColor(OccurrenceStatus status) {
  switch (status) {
    case OccurrenceStatus.critical:
      return const Color(0xFFE53935); // Vermelho
    case OccurrenceStatus.pending:
      return const Color(0xFFF57C00); // Laranja
    case OccurrenceStatus.resolved:
      return const Color(0xFF2E9E5B); // Verde
  }
}

/// Ícone associado a cada estado.
IconData occurrenceStatusIcon(OccurrenceStatus status) {
  switch (status) {
    case OccurrenceStatus.critical:
      return LucideIcons.alertTriangle;
    case OccurrenceStatus.pending:
      return LucideIcons.trash2;
    case OccurrenceStatus.resolved:
      return LucideIcons.check;
  }
}

/// Rótulo curto por estado.
String occurrenceStatusLabel(OccurrenceStatus status) {
  switch (status) {
    case OccurrenceStatus.critical:
      return 'Crítica';
    case OccurrenceStatus.pending:
      return 'Pendente';
    case OccurrenceStatus.resolved:
      return 'Resolvida';
  }
}

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
    final statusColor = occurrenceStatusColor(status);

    if (isCluster) {
      return _ClusterMarker(
        count: clusterCount!,
        color: statusColor,
        onTap: onTap,
      );
    }

    return GestureDetector(
      onTap: onTap ??
          () {
            final occ = occurrence;
            if (occ != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${occ.title}: ${occ.description}',
                    style: const TextStyle(fontFamily: 'Geist'),
                  ),
                  backgroundColor: const Color(0xFF01403A),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
      child: _TeardropPin(
        color: statusColor,
        icon: occurrenceStatusIcon(status),
      ),
    );
  }
}

/// Pin em forma de gota (estilo mapas premium): cabeça circular com ícone,
/// contorno branco, sombra suave e ponta inferior a apontar a coordenada.
class _TeardropPin extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _TeardropPin({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 50,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          CustomPaint(
            size: const Size(40, 50),
            painter: _PinPainter(color: color),
          ),
          Positioned(
            top: 12,
            child: Icon(icon, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  final Color color;

  _PinPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 2.0;
    final double r = size.width / 2 - stroke; // raio da cabeça
    final Offset head = Offset(size.width / 2, r + stroke);

    // Cabeça (círculo) + cauda (triângulo) unidas numa só forma.
    final headPath = Path()
      ..addOval(Rect.fromCircle(center: head, radius: r));
    final tailPath = Path()
      ..moveTo(head.dx - r * 0.66, head.dy + r * 0.5)
      ..lineTo(head.dx + r * 0.66, head.dy + r * 0.5)
      ..lineTo(size.width / 2, size.height)
      ..close();
    final pin = Path.combine(PathOperation.union, headPath, tailPath);

    // Sombra projetada.
    canvas.drawShadow(pin, Colors.black.withValues(alpha: 0.35), 4.0, false);

    // Preenchimento.
    canvas.drawPath(pin, Paint()..color = color);

    // Contorno branco crisp.
    canvas.drawPath(
      pin,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    // Furo interior claro para dar profundidade ao ícone.
    canvas.drawCircle(
      head,
      r - 3,
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Marcador de agrupamento: círculo sólido com contagem, anel branco e halo.
class _ClusterMarker extends StatelessWidget {
  final int count;
  final Color color;
  final VoidCallback? onTap;

  const _ClusterMarker({required this.count, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Halo exterior.
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.18),
              ),
            ),
            // Círculo principal.
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
