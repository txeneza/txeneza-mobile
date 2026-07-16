import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';

class ProfileGamificationCard extends StatelessWidget {
  final int points;
  final int level;
  final List<String> badges;

  const ProfileGamificationCard({
    super.key,
    required this.points,
    required this.level,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Progresso de nível
    final int basePoints = (level - 1) * 100;
    final int nextLevelPoints = level * 100 + 100;
    final int progress = points - basePoints;
    final int total = nextLevelPoints - basePoints;
    final double pct = (progress / total).clamp(0.0, 1.0);

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
            // Título + Nível
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progresso & Conquistas',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.forestGreen,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.trophy,
                      size: 14,
                      color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Nível $level',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Barra de progresso com info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$points pts',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                Text(
                  '$nextLevelPoints pts',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    color: isDark ? Colors.white38 : AppColors.grey600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 6,
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.sageGreen : AppColors.forestGreen,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Medalhas — compacto e sóbrio
            Text(
              'Medalhas',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : AppColors.grey600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: badges.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  final style = _getBadgeStyle(badge);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? style.color.withValues(alpha: 0.08)
                          : style.color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? style.color.withValues(alpha: 0.15)
                            : style.color.withValues(alpha: 0.15),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          style.icon,
                          color: style.color.withValues(alpha: isDark ? 0.8 : 0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          badge,
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : AppColors.grey800,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  _BadgeStyle _getBadgeStyle(String name) {
    if (name.contains('Pioneiro')) {
      return _BadgeStyle(icon: LucideIcons.award, color: const Color(0xFFD4A017));
    } else if (name.contains('Verde') || name.contains('Guardião')) {
      return _BadgeStyle(icon: LucideIcons.leaf, color: const Color(0xFF2E7D6F));
    } else if (name.contains('Ativo') || name.contains('Denunciante')) {
      return _BadgeStyle(icon: LucideIcons.shieldAlert, color: const Color(0xFF5C7AEA));
    }
    return _BadgeStyle(icon: LucideIcons.medal, color: const Color(0xFF6B7280));
  }
}

class _BadgeStyle {
  final IconData icon;
  final Color color;

  _BadgeStyle({required this.icon, required this.color});
}
