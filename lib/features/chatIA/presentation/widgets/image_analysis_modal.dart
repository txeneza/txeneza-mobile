import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../../../core/theme/typography/text_styles.dart';
import '../../data/services/gemini_service.dart';

class ImageAnalysisModal extends StatefulWidget {
  final GeminiService geminiService;
  final Function(String imageName, String imageAsset, String analysisResult) onAnalysisComplete;

  const ImageAnalysisModal({
    super.key,
    required this.geminiService,
    required this.onAnalysisComplete,
  });

  @override
  State<ImageAnalysisModal> createState() => _ImageAnalysisModalState();
}

class _ImageAnalysisModalState extends State<ImageAnalysisModal> {
  bool _isAnalyzing = false;
  String _currentStep = '';
  String _networkStatus = 'Verificando...';
  bool _isOnline = true;

  final List<Map<String, String>> _mockPhotos = [
    {
      'name': 'Lixeira Irregular de Plásticos',
      'description': 'Grande quantidade de garrafas PET e recipientes plásticos obstruindo a calçada na zona central.',
      'asset': 'assets/images/plastic_waste.png',
    },
    {
      'name': 'Foco de Lixo Orgânico',
      'description': 'Restos de alimentos e matéria orgânica acumulados perto de mercado, atraindo insetos.',
      'asset': 'assets/images/organic_waste.png',
    },
    {
      'name': 'Entulho e Restos de Obras',
      'description': 'Resíduos de construção civil, pedregulhos e tijolos abandonados na via pública impedindo trânsito.',
      'asset': 'assets/images/construction_waste.png',
    },
  ];

  Future<void> _checkConnectivity() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    final hasConnection = connectivityResults.any((r) => r != ConnectivityResult.none);
    setState(() {
      _isOnline = hasConnection;
      _networkStatus = hasConnection ? 'Online (Conectado)' : 'Offline (Sem Internet)';
    });
  }

  Future<void> _startImageAnalysis(Map<String, String> photo) async {
    setState(() {
      _isAnalyzing = true;
      _currentStep = 'Verificando conectividade...';
    });

    await _checkConnectivity();
    await Future.delayed(const Duration(milliseconds: 800));

    if (_isOnline) {
      // Flowchart route: Online -> Gemini API
      setState(() {
        _currentStep = 'Conectividade ativa.\nRoteando para API do Gemini 1.5 Flash...';
      });
      await Future.delayed(const Duration(milliseconds: 1000));

      setState(() {
        _currentStep = 'Enviando imagem ao Gemini...\nClassificando resíduos...';
      });

      try {
        final result = await widget.geminiService.analyzeSimulatedImage(
          photo['name']!,
          photo['description']!,
        );

        if (mounted) {
          widget.onAnalysisComplete(photo['name']!, photo['asset']!, result);
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _currentStep = 'Erro ao conectar ao Gemini. Tentando motor local...';
          });
          await Future.delayed(const Duration(milliseconds: 1000));
          _runTensorFlowFallback(photo);
        }
      }
    } else {
      // Flowchart route: Offline -> TensorFlow Lite (Local)
      setState(() {
        _currentStep = 'Sem conectividade detectada.\nRoteando para TensorFlow Lite (Motor Local)...';
      });
      await Future.delayed(const Duration(milliseconds: 1200));

      setState(() {
        _currentStep = 'Executando inferência local offline...';
      });
      await Future.delayed(const Duration(milliseconds: 1000));

      _runTensorFlowFallback(photo);
    }
  }

  void _runTensorFlowFallback(Map<String, String> photo) {
    // Generate structured TensorFlow Lite mock response offline
    String offlineResult = '';
    final name = photo['name']!;
    if (name.contains('Plásticos')) {
      offlineResult = '### [MOTOR LOCAL TENSORFLOW LITE]\n'
          '**Resultado da Análise (Offline):**\n'
          '- **Classificação:** Resíduos Plásticos (Recicláveis)\n'
          '- **Gravidade:** Alta (Obstrução de calçada)\n'
          '- **Ação Local Recomendada:** Coleta Seletiva Seca.\n\n'
          '*Nota: Como você está offline, esta análise foi feita pelo modelo local TensorFlow Lite no dispositivo. A ocorrência foi salva localmente e será enviada à edilidade automaticamente assim que restabelecer conexão.*';
    } else if (name.contains('Orgânico')) {
      offlineResult = '### [MOTOR LOCAL TENSORFLOW LITE]\n'
          '**Resultado da Análise (Offline):**\n'
          '- **Classificação:** Resíduos Orgânicos/Compostáveis\n'
          '- **Gravidade:** Crítica (Perigo à saúde pública)\n'
          '- **Ação Local Recomendada:** Coleta Municipal de Resíduos Sólidos Urbanos Urgente.\n\n'
          '*Nota: Como você está offline, esta análise foi feita pelo modelo local TensorFlow Lite no dispositivo. A ocorrência foi salva localmente e será enviada à edilidade automaticamente assim que restabelecer conexão.*';
    } else {
      offlineResult = '### [MOTOR LOCAL TENSORFLOW LITE]\n'
          '**Resultado da Análise (Offline):**\n'
          '- **Classificação:** Entulho/Resíduos de Construção\n'
          '- **Gravidade:** Média (Obstrução de via)\n'
          '- **Ação Local Recomendada:** Remoção mecanizada pela divisão de infraestrutura.\n\n'
          '*Nota: Como você está offline, esta análise foi feita pelo modelo local TensorFlow Lite no dispositivo. A ocorrência foi salva localmente e será enviada à edilidade automaticamente assim que restabelecer conexão.*';
    }

    if (mounted) {
      widget.onAnalysisComplete(photo['name']!, photo['asset']!, offlineResult);
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            // Handle bar
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

            if (!_isAnalyzing) ...[
              Text(
                'Simulação de Fotos para Classificação',
                style: TextStyles.subtitleMedium.copyWith(
                  color: isDark ? AppColors.white : AppColors.forestGreen,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpaceXS,
              Text(
                'Escolha um cenário para simular o fluxograma de classificação de resíduos da Txeneza.',
                style: TextStyles.captionLarge.copyWith(
                  color: AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpaceMD,

              // Status of network
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: _isOnline 
                      ? AppColors.mintGreen.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isOnline ? AppColors.sageGreen : AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isOnline ? LucideIcons.wifi : LucideIcons.wifiOff,
                      color: _isOnline ? AppColors.forestGreen : AppColors.error,
                      size: 18,
                    ),
                    AppSpacing.horizontalSpaceSM,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status de Rede Detectado:',
                            style: TextStyles.captionSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _isOnline ? AppColors.forestGreen : AppColors.error,
                            ),
                          ),
                          Text(
                            _networkStatus,
                            style: TextStyles.captionLarge.copyWith(
                              color: _isOnline ? AppColors.forestGreen : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalSpaceMD,

              // Grid list of photos
              ..._mockPhotos.map((photo) {
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  color: isDark ? AppColors.grey800.withValues(alpha: 0.5) : AppColors.grey100,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? AppColors.grey800 : AppColors.grey300,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _startImageAnalysis(photo),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.forestGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.image,
                              color: AppColors.forestGreen,
                              size: 28,
                            ),
                          ),
                          AppSpacing.horizontalSpaceMD,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  photo['name']!,
                                  style: TextStyles.captionLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.white : AppColors.grey900,
                                  ),
                                ),
                                AppSpacing.verticalSpaceXXS,
                                Text(
                                  photo['description']!,
                                  style: TextStyles.captionSmall.copyWith(
                                    color: AppColors.grey600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            color: AppColors.grey600,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ] else ...[
              // Processing state showing the flowchart decision path
              Column(
                children: [
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Processando Ocorrência',
                    style: TextStyles.subtitleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.forestGreen,
                    ),
                  ),
                  AppSpacing.verticalSpaceSM,
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey800 : AppColors.grey100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.grey800 : AppColors.grey300,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isOnline ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                              color: _isOnline ? AppColors.success : AppColors.warning,
                              size: 16,
                            ),
                            AppSpacing.horizontalSpaceXS,
                            Text(
                              _isOnline ? 'Online (API Gemini)' : 'Offline (TensorFlow Lite)',
                              style: TextStyles.captionLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _isOnline ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.verticalSpaceSM,
                        Text(
                          _currentStep,
                          textAlign: TextAlign.center,
                          style: TextStyles.captionLarge.copyWith(
                            color: isDark ? AppColors.white : AppColors.grey800,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
