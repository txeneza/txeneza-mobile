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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.transparent,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isDark 
              ? const Color(0xFF1E1E1E).withValues(alpha: 0.85) 
              : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.08) 
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.3) 
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
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
                SvgPicture.asset(
                  AppIcons.logo,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
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
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72.0); // 56 height + 16 vertical padding
}
