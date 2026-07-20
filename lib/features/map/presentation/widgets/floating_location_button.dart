import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';

/// Botão flutuante para recentrar o mapa na localização GPS do utilizador.
class FloatingLocationButton extends StatefulWidget {
  final bool isResolving;
  final VoidCallback onPressed;

  const FloatingLocationButton({
    super.key,
    required this.isResolving,
    required this.onPressed,
  });

  @override
  State<FloatingLocationButton> createState() => _FloatingLocationButtonState();
}

class _FloatingLocationButtonState extends State<FloatingLocationButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.isResolving) {
      _animController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant FloatingLocationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isResolving != oldWidget.isResolving) {
      if (widget.isResolving) {
        _animController.repeat();
      } else {
        _animController.stop();
        _animController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Recentrar o mapa na localização do utilizador',
      button: true,
      child: Tooltip(
        message: 'Recentrar no meu GPS',
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFE8E5DD),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onPressed,
              child: Center(
                child: RotationTransition(
                  turns: _animController,
                  child: Icon(
                    widget.isResolving
                        ? LucideIcons.loaderCircle
                        : LucideIcons.locateFixed,
                    size: 20,
                    color: AppColors.forestGreen,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
