import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../../../app.dart' show themeProvider;

class ProfileSettingsSection extends StatelessWidget {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool offlineSync;
  final String language;
  final Function(bool) onPushChanged;
  final Function(bool) onEmailChanged;
  final Function(bool) onOfflineChanged;
  final Function(String) onLanguageChanged;

  const ProfileSettingsSection({
    super.key,
    required this.pushNotifications,
    required this.emailNotifications,
    required this.offlineSync,
    required this.language,
    required this.onPushChanged,
    required this.onEmailChanged,
    required this.onOfflineChanged,
    required this.onLanguageChanged,
  });

  void _showLanguageDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? DarkColors.surface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Selecione o Idioma',
            style: TextStyle(
              fontFamily: 'Geist',
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.forestGreen,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(context, 'Português (MZ)', isDark),
              _buildLanguageOption(context, 'English (US)', isDark),
              _buildLanguageOption(context, 'Chindau', isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, String lang, bool isDark) {
    final isSelected = language == lang;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text(
        lang,
        style: TextStyle(
          fontFamily: 'Geist',
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? (isDark ? AppColors.sageGreen : AppColors.forestGreen)
              : (isDark ? Colors.white70 : AppColors.grey800),
        ),
      ),
      trailing: isSelected
          ? Icon(LucideIcons.check, color: isDark ? AppColors.sageGreen : AppColors.forestGreen, size: 18)
          : null,
      onTap: () {
        onLanguageChanged(lang);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Mapeia ThemeMode para label amigável
    String themeLabel = 'Claro';
    if (themeProvider.themeMode == ThemeMode.dark) {
      themeLabel = 'Escuro';
    } else if (themeProvider.themeMode == ThemeMode.system) {
      themeLabel = 'Automático';
    }

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
              'Configurações',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 12),

            // Tema
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(LucideIcons.sunMoon, color: iconColor, size: 20),
              title: Text(
                'Tema do Aplicativo',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
              subtitle: Text(
                themeLabel,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: isDark ? Colors.white38 : AppColors.grey600,
                ),
              ),
              trailing: DropdownButton<ThemeMode>(
                value: themeProvider.themeMode,
                dropdownColor: isDark ? DarkColors.surface : Colors.white,
                underline: const SizedBox(),
                icon: Icon(LucideIcons.chevronDown, size: 14, color: iconColor),
                items: [
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Claro  ', style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13,
                      color: isDark ? Colors.white70 : AppColors.grey800,
                    )),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text('Escuro  ', style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13,
                      color: isDark ? Colors.white70 : AppColors.grey800,
                    )),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('Sistema  ', style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13,
                      color: isDark ? Colors.white70 : AppColors.grey800,
                    )),
                  ),
                ],
                onChanged: (mode) {
                  if (mode != null) {
                    themeProvider.setThemeMode(mode);
                  }
                },
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.grey200),

            // Idioma
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(LucideIcons.globe, color: iconColor, size: 20),
              title: Text(
                'Idioma',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
              subtitle: Text(
                language,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: isDark ? Colors.white38 : AppColors.grey600,
                ),
              ),
              trailing: Icon(LucideIcons.chevronRight, size: 16, color: iconColor),
              onTap: () => _showLanguageDialog(context, isDark),
            ),
            Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.grey200),

            // Push Notifications
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(LucideIcons.bell, color: iconColor, size: 20),
              title: Text(
                'Notificações Push',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
              subtitle: Text(
                'Receber alertas de denúncias no celular.',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 11,
                  color: isDark ? Colors.white38 : AppColors.grey600,
                ),
              ),
              value: pushNotifications,
              activeColor: isDark ? AppColors.sageGreen : AppColors.forestGreen,
              onChanged: onPushChanged,
            ),
            Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.grey200),

            // Email Notifications
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(LucideIcons.mail, color: iconColor, size: 20),
              title: Text(
                'Notificações por Email',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
              subtitle: Text(
                'Receber resumos de resoluções de problemas.',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 11,
                  color: isDark ? Colors.white38 : AppColors.grey600,
                ),
              ),
              value: emailNotifications,
              activeColor: isDark ? AppColors.sageGreen : AppColors.forestGreen,
              onChanged: onEmailChanged,
            ),
            Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.grey200),

            // Offline Sync
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(LucideIcons.wifiOff, color: iconColor, size: 20),
              title: Text(
                'Sincronização Offline',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
              subtitle: Text(
                'Guardar reportes e enviar quando houver conexão.',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 11,
                  color: isDark ? Colors.white38 : AppColors.grey600,
                ),
              ),
              value: offlineSync,
              activeColor: isDark ? AppColors.sageGreen : AppColors.forestGreen,
              onChanged: onOfflineChanged,
            ),
          ],
        ),
      ),
    );
  }
}
