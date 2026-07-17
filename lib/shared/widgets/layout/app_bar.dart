import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/icons/app_icons.dart';
import '../../../../features/map/presentation/widgets/connectivity_indicator.dart';

class TxenezaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isOnline;
  final VoidCallback onConnectivityTap;

  const TxenezaAppBar({
    super.key,
    required this.isOnline,
    required this.onConnectivityTap,
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
              // Right side connectivity indicator
              ConnectivityIndicator(
                isOnline: isOnline,
                onTap: onConnectivityTap,
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
