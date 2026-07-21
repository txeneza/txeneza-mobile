import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/icons/app_icons.dart';
import '../../../../features/map/presentation/widgets/connectivity_indicator.dart';

class TxenezaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isOnline;
  final VoidCallback onConnectivityTap;
  final int unreadCount;
  final VoidCallback? onBellTap;

  const TxenezaAppBar({
    super.key,
    required this.isOnline,
    required this.onConnectivityTap,
    this.unreadCount = 0,
    this.onBellTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1A1A1A)
                : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE8E5DD),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo & Title
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícone SVG com fundo circular subtil
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.forestGreen.withValues(alpha: isDark ? 0.15 : 0.08),
                    ),
                    padding: const EdgeInsets.all(5),
                    child: SvgPicture.asset(
                      AppIcons.logo,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        isDark ? AppColors.limeGreen : AppColors.forestGreen,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : AppColors.forestGreen,
                      ),
                      children: [
                        const TextSpan(text: 'T'),
                        TextSpan(
                          text: 'x',
                          style: TextStyle(
                            color: isDark ? AppColors.lightLime : AppColors.limeGreen,
                          ),
                        ),
                        const TextSpan(text: 'eneza'),
                      ],
                    ),
                  ),
                ],
              ),
              // Right side: sino de notificações + indicador de conectividade
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onBellTap != null) ...[
                    _NotificationBell(
                      unreadCount: unreadCount,
                      isDark: isDark,
                      onTap: onBellTap!,
                    ),
                    const SizedBox(width: 8),
                  ],
                  ConnectivityIndicator(
                    isOnline: isOnline,
                    onTap: onConnectivityTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72.0);
}

/// Sino de notificações com badge numérico de não lidas. Sem número
/// nenhum quando a contagem é zero (só o ícone).
class _NotificationBell extends StatelessWidget {
  final int unreadCount;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationBell({
    required this.unreadCount,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 24,
              color: isDark ? Colors.white70 : AppColors.forestGreen,
            ),
            if (unreadCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
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
