import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../../../core/theme/typography/text_styles.dart';
import '../../data/services/gemini_service.dart';

/// Escolhe uma imagem real (câmara ou galeria) e classifica-a com o Gemini.
class ImageAnalysisModal extends StatefulWidget {
  final GeminiService geminiService;

  /// Devolve o caminho da imagem e o texto da classificação da Xeni.
  final void Function(String imagePath, String analysisResult)
      onAnalysisComplete;

  const ImageAnalysisModal({
    super.key,
    required this.geminiService,
    required this.onAnalysisComplete,
  });

  @override
  State<ImageAnalysisModal> createState() => _ImageAnalysisModalState();
}

class _ImageAnalysisModalState extends State<ImageAnalysisModal> {
  final _picker = ImagePicker();
  bool _isAnalyzing = false;

  Future<void> _pickAndAnalyze(ImageSource source) async {
    // A classificação depende do Gemini, que precisa de internet.
    final results = await Connectivity().checkConnectivity();
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    if (!isOnline) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A classificação de imagens precisa de internet. Tente quando estiver online.',
            style: TextStyle(fontFamily: 'Geist'),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final XFile? photo = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (photo == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final bytes = await photo.readAsBytes();
      final result = await widget.geminiService.classifyImage(bytes);
      if (!mounted) return;
      widget.onAnalysisComplete(photo.path, result);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível classificar a imagem. Tente novamente.',
            style: TextStyle(fontFamily: 'Geist'),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey900 : AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.grey800 : AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AppSpacing.verticalSpaceMD,

            if (_isAnalyzing) ...[
              const SizedBox(height: 20),
              const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
                ),
              ),
              AppSpacing.verticalSpaceMD,
              Text(
                'A Xeni está a classificar a imagem...',
                textAlign: TextAlign.center,
                style: TextStyles.captionLarge.copyWith(
                  color: isDark ? AppColors.white : AppColors.grey800,
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              Text(
                'Classificar resíduo',
                style: TextStyles.subtitleMedium.copyWith(
                  color: isDark ? AppColors.white : AppColors.forestGreen,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpaceXS,
              Text(
                'Tire uma foto do resíduo ou escolha da galeria. A Xeni identifica o tipo de resíduo.',
                style: TextStyles.captionLarge.copyWith(color: AppColors.grey600),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpaceMD,
              _optionTile(
                isDark,
                icon: LucideIcons.camera,
                title: 'Tirar foto',
                onTap: () => _pickAndAnalyze(ImageSource.camera),
              ),
              AppSpacing.verticalSpaceSM,
              _optionTile(
                isDark,
                icon: LucideIcons.image,
                title: 'Escolher da galeria',
                onTap: () => _pickAndAnalyze(ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _optionTile(
    bool isDark, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? AppColors.grey800.withValues(alpha: 0.5) : AppColors.grey100,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.forestGreen, size: 24),
              ),
              AppSpacing.horizontalSpaceMD,
              Expanded(
                child: Text(
                  title,
                  style: TextStyles.captionLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.grey900,
                  ),
                ),
              ),
              const Icon(LucideIcons.chevronRight,
                  color: AppColors.grey600, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
