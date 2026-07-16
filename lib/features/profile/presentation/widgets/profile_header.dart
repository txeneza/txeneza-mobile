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

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    final first = parts.first[0];
    final last = parts.last[0];
    return '$first$last'.toUpperCase();
  }

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
              // Avatar com Iniciais
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: isDark ? AppColors.forestGreen : AppColors.mintGreen,
                  child: Text(
                    _getInitials(fullName),
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
