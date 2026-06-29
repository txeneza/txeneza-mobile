import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/config/routes/app_routes.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';

class ProfilePrivacySection extends StatelessWidget {
  final bool locationPermission;
  final bool cameraPermission;
  final Function(bool) onLocationPermissionChanged;
  final Function(bool) onCameraPermissionChanged;

  const ProfilePrivacySection({
    super.key,
    required this.locationPermission,
    required this.cameraPermission,
    required this.onLocationPermissionChanged,
    required this.onCameraPermissionChanged,
  });

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
              'Privacidade & Segurança',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 12),

            // Alterar Palavra-passe
            _buildNavTile(
              context: context,
              icon: LucideIcons.keyRound,
              title: 'Alterar Palavra-passe',
              iconColor: iconColor,
              isDark: isDark,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.changePassword),
            ),
            _divider(isDark),

            // Permissão de Localização
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(LucideIcons.mapPin, color: iconColor, size: 20),
              title: Text(
                'Permissão de Localização',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
              subtitle: Text(
                'Permitir mapeamento automático pelo GPS.',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 11,
                  color: isDark ? Colors.white38 : AppColors.grey600,
                ),
              ),
              value: locationPermission,
              activeColor: isDark ? AppColors.sageGreen : AppColors.forestGreen,
              onChanged: onLocationPermissionChanged,
            ),
            _divider(isDark),

            // Permissão de Câmara
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(LucideIcons.camera, color: iconColor, size: 20),
              title: Text(
                'Permissão de Câmara',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
              subtitle: Text(
                'Permitir capturar fotos para denúncias.',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 11,
                  color: isDark ? Colors.white38 : AppColors.grey600,
                ),
              ),
              value: cameraPermission,
              activeColor: isDark ? AppColors.sageGreen : AppColors.forestGreen,
              onChanged: onCameraPermissionChanged,
            ),
            _divider(isDark),

            // Política de Privacidade
            _buildNavTile(
              context: context,
              icon: LucideIcons.shieldCheck,
              title: 'Política de Privacidade',
              iconColor: iconColor,
              isDark: isDark,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.privacyPolicy),
            ),
            _divider(isDark),

            // Termos de Utilização
            _buildNavTile(
              context: context,
              icon: LucideIcons.fileText,
              title: 'Termos de Utilização',
              iconColor: iconColor,
              isDark: isDark,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.termsOfUse),
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
