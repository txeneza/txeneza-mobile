import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';

class ProfileHeader extends StatelessWidget {
  final String fullName;
  final bool isVerified;

  const ProfileHeader({
    super.key,
    required this.fullName,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  DarkColors.surface,
                  const Color(0xFF0D2B26),
                ]
              : [
                  AppColors.forestGreen,
                  const Color(0xFF024D45),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.xl,
            bottom: AppSpacing.xl,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
          ),
          child: Column(
            children: [
              // Nome do utilizador
              Text(
                fullName,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 10),

              // Badge de verificação — pill chip sóbrio
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isVerified
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isVerified
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.error.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVerified ? LucideIcons.shieldCheck : LucideIcons.alertTriangle,
                      color: isVerified
                          ? Colors.white.withValues(alpha: 0.9)
                          : const Color(0xFFFF8A80),
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isVerified ? 'Conta Verificada' : 'Não Verificado',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isVerified
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFFFF8A80),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
