import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/colors/app_colors.dart';

/// Banner discreto e moderno para indicar modo offline e pendências de sincronização (RF-013).
class OfflineStatusBanner extends StatelessWidget {
  final bool isOnline;
  final int pendingCount;
  final VoidCallback? onSyncTap;

  const OfflineStatusBanner({
    super.key,
    required this.isOnline,
    required this.pendingCount,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = !isOnline
        ? AppColors.warning.withValues(alpha: 0.15)
        : AppColors.forestGreen.withValues(alpha: 0.12);
    final borderColor = !isOnline ? AppColors.warning : AppColors.forestGreen;
    final textColor = !isOnline
        ? (isDark ? Colors.orangeAccent : AppColors.grey900)
        : (isDark ? AppColors.sageGreen : AppColors.forestGreen);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            !isOnline ? LucideIcons.wifiOff : LucideIcons.cloudUpload,
            size: 18,
            color: borderColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              !isOnline
                  ? (pendingCount > 0
                      ? 'Modo Offline: $pendingCount denúncia(s) pendente(s).'
                      : 'Sem ligação à internet.')
                  : '$pendingCount denúncia(s) pendente(s) por sincronizar.',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          if (pendingCount > 0 && onSyncTap != null)
            TextButton(
              onPressed: onSyncTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isOnline ? 'Sincronizar' : 'Ver Fila',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: borderColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.chevronRight, size: 14, color: borderColor),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
