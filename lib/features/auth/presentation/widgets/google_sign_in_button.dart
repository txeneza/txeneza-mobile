import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/auth_strings.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isDark;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: isDark ? AppColors.grey800 : AppColors.grey300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                AuthStrings.orDivider,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.grey300 : AppColors.grey600,
                ),
              ),
            ),
            Expanded(child: Divider(color: isDark ? AppColors.grey800 : AppColors.grey300)),
          ],
        ),
        AppSpacing.verticalSpaceLG,
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: SvgPicture.asset('assets/icons/google.svg', width: 20, height: 20),
          label: Text(
            AuthStrings.continueWithGoogle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.white : AppColors.grey900,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: isDark ? DarkColors.primary : AppColors.grey300),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
        ),
      ],
    );
  }
}
