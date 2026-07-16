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
  final String? simulatedImageName;
  final String? simulatedImageAsset;
  final VoidCallback? onCopy;
  final VoidCallback? onExportPdf;
  final VoidCallback? onEscalate;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.time,
    this.simulatedImageName,
    this.simulatedImageAsset,
    this.onCopy,
    this.onExportPdf,
    this.onEscalate,
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
    if (onCopy != null) onCopy!();
  }

  void _exportPdf(BuildContext context) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Simulated PDF Export
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(seconds: 1), () {
          navigator.pop(); // Dismiss loading dialog
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Relatório PDF exportado com sucesso! Salvo em Downloads.',
                style: TextStyle(fontFamily: 'Geist'),
              ),
              backgroundColor: AppColors.forestGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
        return const Center(
          child: Card(
            color: AppColors.forestGreen,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.sageGreen),
                  ),
                  AppSpacing.verticalSpaceMD,
                  Text(
                    'Gerando PDF do Boletim...',
                    style: TextStyle(
                      color: AppColors.white,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (onExportPdf != null) onExportPdf!();
  }

  void _escalateOccurrence(BuildContext context) {
    // Simulated Municipal escalation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ocorrência enviada para o canal oficial da Edilidade da Beira. Protocolo: TX-2026-0817.',
          style: TextStyle(fontFamily: 'Geist'),
        ),
        backgroundColor: AppColors.forestGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (onEscalate != null) onEscalate!();
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
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message Card
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
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
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
                  // Image frame if available
                  if (simulatedImageAsset != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        color: isDark ? AppColors.grey800 : AppColors.grey100,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Show simulated representation/icon since assets might not exist
                            Image.asset(
                              simulatedImageAsset!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.forestGreen.withValues(alpha: 0.2),
                                  child: const Center(
                                    child: Icon(
                                      LucideIcons.image,
                                      color: AppColors.forestGreen,
                                      size: 40,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: AppSpacing.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  simulatedImageName ?? 'Foto Anexada',
                                  style: TextStyles.captionSmall.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AppSpacing.verticalSpaceSM,
                  ],

                  // Text body
                  Text(
                    text,
                    style: TextStyles.captionLarge.copyWith(
                      color: isUser ? AppColors.white : (isDark ? AppColors.white : AppColors.grey900),
                      height: 1.4,
                    ),
                  ),
                  AppSpacing.verticalSpaceXXS,

                  // Timestamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        time,
                        style: TextStyles.captionSmall.copyWith(
                          color: isUser ? AppColors.sageGreen : AppColors.grey600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bot Actions bar (Premium options)
            if (!isUser) ...[
              AppSpacing.verticalSpaceXXS,
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: Row(
                  children: [
                    _ActionButton(
                      icon: LucideIcons.copy,
                      label: 'Copiar',
                      onPressed: () => _copyToClipboard(context),
                    ),
                    AppSpacing.horizontalSpaceSM,
                    _ActionButton(
                      icon: LucideIcons.fileSpreadsheet,
                      label: 'PDF',
                      onPressed: () => _exportPdf(context),
                    ),
                    AppSpacing.horizontalSpaceSM,
                    _ActionButton(
                      icon: LucideIcons.send,
                      label: 'Edilidade',
                      onPressed: () => _escalateOccurrence(context),
                    ),
                  ],
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
        child: Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
            ),
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
