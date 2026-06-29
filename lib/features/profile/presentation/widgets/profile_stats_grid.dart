import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';

class ProfileStatsGrid extends StatelessWidget {
  final int reportsSubmitted;
  final int reportsResolved;
  final int reportsPending;

  const ProfileStatsGrid({
    super.key,
    required this.reportsSubmitted,
    required this.reportsResolved,
    required this.reportsPending,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              'Resumo de Atividade',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Enviados',
                    value: reportsSubmitted,
                    icon: LucideIcons.send,
                    color: const Color(0xFF5C7AEA),
                    isDark: isDark,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.grey200,
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Resolvidos',
                    value: reportsResolved,
                    icon: LucideIcons.checkCircle2,
                    color: const Color(0xFF2E7D6F),
                    isDark: isDark,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.grey200,
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Pendentes',
                    value: reportsPending,
                    icon: LucideIcons.clock4,
                    color: const Color(0xFFE67E22),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: color.withValues(alpha: isDark ? 0.85 : 0.75),
        ),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.grey900,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white60 : AppColors.grey600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
