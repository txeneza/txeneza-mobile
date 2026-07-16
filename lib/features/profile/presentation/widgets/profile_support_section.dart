import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/config/routes/app_routes.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';

class ProfileSupportSection extends StatelessWidget {
  const ProfileSupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white38 : AppColors.grey600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? DarkColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.grey200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suporte',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 12),

            // Ajuda / FAQ
            _buildNavTile(
              context: context,
              icon: LucideIcons.helpCircle,
              title: 'Ajuda / FAQ',
              iconColor: iconColor,
              isDark: isDark,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.helpFaq),
            ),
            _divider(isDark),

            // Reportar problema
            _buildNavTile(
              context: context,
              icon: LucideIcons.alertCircle,
              title: 'Reportar problema',
              iconColor: iconColor,
              isDark: isDark,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.reportProblem),
            ),
            _divider(isDark),

            // Contacto
            _buildNavTile(
              context: context,
              icon: LucideIcons.messageSquare,
              title: 'Contacto',
              iconColor: iconColor,
              isDark: isDark,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.contact),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor, size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : AppColors.grey900,
        ),
      ),
      trailing: Icon(LucideIcons.chevronRight, size: 16, color: iconColor),
      onTap: onTap,
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.grey200,
    );
  }
}
