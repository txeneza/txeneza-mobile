import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../../../core/theme/typography/text_styles.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String time;

  /// Caminho de uma imagem real anexada (foto da ocorrência), se existir.
  final String? imagePath;

  /// Indica se esta resposta é uma classificação de resíduo que permite submeter denúncia.
  final bool canReport;

  /// Caminho do ficheiro de imagem associado para submissão da denúncia.
  final String? reportImagePath;

  /// Ação invocada ao selecionar 'Enviar Denúncia'.
  final VoidCallback? onReport;

  /// Ação invocada ao selecionar 'Saber mais sobre o resíduo'.
  final VoidCallback? onLearnMore;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.time,
    this.imagePath,
    this.canReport = false,
    this.reportImagePath,
    this.onReport,
    this.onLearnMore,
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
          maxWidth: MediaQuery.of(context).size.width * 0.85,
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
                    : (isDark ? DarkColors.surface : AppColors.white),
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
                        color: isDark
                            ? DarkColors.accent.withValues(alpha: 0.15)
                            : AppColors.grey200,
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

                  isUser
                      ? Text(
                          text,
                          style: TextStyles.captionLarge.copyWith(
                            color: AppColors.white,
                            height: 1.4,
                          ),
                        )
                      : MarkdownBody(
                          data: text,
                          selectable: false,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyles.captionLarge.copyWith(
                              color: isDark ? AppColors.white : AppColors.grey900,
                              height: 1.4,
                            ),
                            strong: TextStyles.captionLarge.copyWith(
                              color: isDark ? DarkColors.accent : AppColors.forestGreen,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                            em: TextStyles.captionLarge.copyWith(
                              color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                            listBullet: TextStyles.captionLarge.copyWith(
                              color: isDark ? DarkColors.accent : AppColors.forestGreen,
                            ),
                            code: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 12,
                              color: isDark ? DarkColors.accent : AppColors.forestGreen,
                              backgroundColor: isDark
                                  ? AppColors.grey900.withValues(alpha: 0.5)
                                  : AppColors.grey100,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: isDark ? AppColors.grey900 : AppColors.grey100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            h1: TextStyles.titleLarge.copyWith(
                              color: isDark ? Colors.white : AppColors.grey900,
                            ),
                            h2: TextStyles.titleMedium.copyWith(
                              color: isDark ? Colors.white : AppColors.grey900,
                            ),
                            h3: TextStyles.subtitleLarge.copyWith(
                              color: isDark ? Colors.white : AppColors.grey900,
                            ),
                          ),
                        ),

                  // Cartão interativo para submeter como denúncia ou tirar mais dúvidas
                  if (!isUser && canReport && reportImagePath != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.grey900.withValues(alpha: 0.5)
                            : AppColors.mintGreen.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.forestGreen.withValues(alpha: 0.4)
                              : AppColors.sageGreen.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.sparkles,
                                  size: 15, color: AppColors.forestGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pretende reportar esta situação?',
                                  style: TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.forestGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: const Icon(LucideIcons.camera, size: 16),
                            label: const Text(
                              'Enviar Denúncia',
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forestGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            onPressed: onReport,
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            icon: const Icon(LucideIcons.helpCircle, size: 15),
                            label: const Text(
                              'Saber mais sobre este resíduo',
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  isDark ? AppColors.grey300 : AppColors.grey800,
                              side: BorderSide(
                                color: isDark ? Colors.white24 : AppColors.grey300,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: onLearnMore,
                          ),
                        ],
                      ),
                    ),
                  ],

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
                color: isDark ? DarkColors.accent : AppColors.forestGreen),
            AppSpacing.horizontalSpaceXXS,
            Text(
              label,
              style: TextStyles.captionSmall.copyWith(
                color: isDark ? DarkColors.accent : AppColors.forestGreen,
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
