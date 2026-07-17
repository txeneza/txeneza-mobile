import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app.dart'; // import themeProvider
import '../../../../core/config/routes/app_routes.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';

class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white38 : AppColors.grey600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Material(
        color: isDark ? DarkColors.surface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.grey200,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Definições',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 12),
  
              // Tema Escuro
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(LucideIcons.moon, color: iconColor, size: 20),
                title: Text(
                  'Tema Escuro',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                trailing: ListenableBuilder(
                  listenable: themeProvider,
                  builder: (context, _) {
                    return Switch(
                      value: themeProvider.isDarkMode,
                      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.forestGreen;
                        }
                        return AppColors.grey600;
                      }),
                      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.sageGreen;
                        }
                        return AppColors.grey300;
                      }),
                      onChanged: (val) {
                        themeProvider.toggleTheme();
                      },
                    );
                  },
                ),
              ),
              _divider(isDark),
  
              // Alterar Password
              _buildNavTile(
                context: context,
                icon: LucideIcons.lock,
                title: 'Alterar Password',
                iconColor: iconColor,
                isDark: isDark,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.changePassword),
              ),
              _divider(isDark),
  
              // Política de Privacidade
              _buildNavTile(
                context: context,
                icon: LucideIcons.shield,
                title: 'Política de Privacidade',
                iconColor: iconColor,
                isDark: isDark,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.privacyPolicy),
              ),
              _divider(isDark),
  
              // Termos de Uso
              _buildNavTile(
                context: context,
                icon: LucideIcons.fileText,
                title: 'Termos de Uso',
                iconColor: iconColor,
                isDark: isDark,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.termsOfUse),
              ),
            ],
          ),
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
