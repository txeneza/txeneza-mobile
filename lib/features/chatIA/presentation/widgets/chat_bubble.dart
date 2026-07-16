import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../../../core/theme/typography/text_styles.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String time;

  /// Caminho de uma imagem real anexada (foto da ocorrência), se existir.
  final String? imagePath;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.time,
    this.imagePath,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copiado para a área de transferência!'),
        backgroundColor: AppColors.forestGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [AppColors.forestGreen, Color(0xFF025c53)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser
                    ? null
                    : (isDark ? AppColors.grey900 : AppColors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isDark ? AppColors.grey800 : AppColors.grey200,
                        width: 1.0,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? AppColors.forestGreen.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8.0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagem real anexada, se houver.
                  if (imagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(imagePath!),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 160,
                          color: AppColors.forestGreen.withValues(alpha: 0.2),
                          child: const Center(
                            child: Icon(LucideIcons.image,
                                color: AppColors.forestGreen, size: 40),
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.verticalSpaceSM,
                  ],

                  Text(
                    text,
                    style: TextStyles.captionLarge.copyWith(
                      color: isUser
                          ? AppColors.white
                          : (isDark ? AppColors.white : AppColors.grey900),
                      height: 1.4,
                    ),
                  ),
                  AppSpacing.verticalSpaceXXS,

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        time,
                        style: TextStyles.captionSmall.copyWith(
                          color:
                              isUser ? AppColors.sageGreen : AppColors.grey600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Ação da resposta da Xeni: copiar (real).
            if (!isUser) ...[
              AppSpacing.verticalSpaceXXS,
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: _ActionButton(
                  icon: LucideIcons.copy,
                  label: 'Copiar',
                  onPressed: () => _copyToClipboard(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: isDark ? AppColors.sageGreen : AppColors.forestGreen),
            AppSpacing.horizontalSpaceXXS,
            Text(
              label,
              style: TextStyles.captionSmall.copyWith(
                color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
