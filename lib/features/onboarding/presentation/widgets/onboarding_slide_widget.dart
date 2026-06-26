import 'package:flutter/material.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../../../core/theme/spacing/app_radius.dart';

class OnboardingFeature {
  final IconData icon;
  final String label;

  const OnboardingFeature({
    required this.icon,
    required this.label,
  });
}

class OnboardingSlideWidget extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final List<OnboardingFeature> features;

  const OnboardingSlideWidget({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    this.features = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Container with subtle shadow and background decoration
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: AppRadius.borderXL,
                color: isDark 
                    ? theme.colorScheme.surface.withValues(alpha: 0.5)
                    : theme.colorScheme.surface.withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative background shapes for rich aesthetics
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.tertiary.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  // Image Illustration
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Title & Description Area
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalSpaceSM,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ),
                if (features.isNotEmpty) ...[
                  AppSpacing.verticalSpaceLG,
                  // Dynamic wrap grid for featured items
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    alignment: WrapAlignment.center,
                    children: features.map((feature) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: AppRadius.borderLG,
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              feature.icon,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            AppSpacing.horizontalSpaceXS,
                            Text(
                              feature.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
