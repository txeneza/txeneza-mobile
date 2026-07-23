import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/colors/app_colors.dart';
import '../../../core/theme/colors/dark_colors.dart';
import '../../chatIA/data/services/gemini_service.dart';
import '../../chatIA/domain/denuncia_ai_classification_result.dart';
import '../../map/domain/beira_geo.dart';
import '../data/categoria_datasource.dart';
import '../domain/categoria.dart';
import '../domain/denuncia_draft.dart';
import '../domain/gravidade.dart';
import 'denuncia_controller.dart';

/// Resultado devolvido ao fechar a página, para a home saber o que aconteceu.
enum DenunciaResult { sentOnline, queuedOffline }

/// Fluxo de captura de denúncia: foto → GPS + validação Beira → IA (Gemini) →
/// categoria + gravidade → submeter (online ou fila offline).
class DenunciaCapturePage extends StatefulWidget {
  final bool isOnline;

  /// Foto já capturada, usada quando o Android matou a app durante a câmara e
  /// recuperámos o ficheiro via `retrieveLostData` (ver home_screen).
  final String? initialImagePath;

  const DenunciaCapturePage({
    super.key,
    required this.isOnline,
    this.initialImagePath,
  });

  @override
  State<DenunciaCapturePage> createState() => _DenunciaCapturePageState();
}

class _DenunciaCapturePageState extends State<DenunciaCapturePage> {
  final _controller = DenunciaController();
  final _categoriaDataSource = CategoriaDataSource();
  final _geminiService = GeminiService();
  final _descricaoController = TextEditingController();
  final _picker = ImagePicker();

  String? _imagePath;
  LatLng? _location;
  double? _locationAccuracy;
  bool _locationInsideBeira = false;
  bool _resolvingLocation = false;
  String? _locationError;

  List<Categoria> _categorias = [];
  Categoria? _selectedCategoria;
  Gravidade _gravidade = Gravidade.media;

  // Estado da Classificação por IA (RF-010, RF-011, RN-005)
  bool _isAnalyzingAI = false;
  bool _showManualInputs = false;
  DenunciaAIClassificationResult? _aiResult;
  Categoria? _aiOriginalCategoria;
  Gravidade? _aiOriginalGravidade;

  bool get _isManualCorrectionApplied =>
      _aiResult != null &&
      (_selectedCategoria != _aiOriginalCategoria || _gravidade != _aiOriginalGravidade);

  @override
  void initState() {
    super.initState();
    _loadCategorias();
    // Foto recuperada após o Android ter matado a app durante a câmara.
    if (widget.initialImagePath != null) {
      _imagePath = widget.initialImagePath;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveLocation();
        _runAIClassification(widget.initialImagePath!);
      });
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    try {
      final cats = await _categoriaDataSource.fetchAll();
      if (!mounted) return;
      final effectiveCats = cats.isNotEmpty ? cats : Categoria.defaultOfflineCategorias;
      setState(() {
        _categorias = effectiveCats;
        if (_selectedCategoria == null && _categorias.isNotEmpty) {
          _selectedCategoria = _categorias.first;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categorias = Categoria.defaultOfflineCategorias;
        if (_selectedCategoria == null && _categorias.isNotEmpty) {
          _selectedCategoria = _categorias.first;
        }
      });
    }
  }

  Future<void> _runAIClassification(String imagePath) async {
    if (!widget.isOnline) return;

    setState(() {
      _isAnalyzingAI = true;
      _aiResult = null;
    });

    try {
      final fileBytes = await File(imagePath).readAsBytes();
      final aiResult = await _geminiService.classifyReportImage(fileBytes);
      if (!mounted) return;

      if (aiResult != null) {
        _aiResult = aiResult;
        _gravidade = aiResult.gravidadeSugerida;
        _aiOriginalGravidade = aiResult.gravidadeSugerida;
        _descricaoController.text = aiResult.explicacao;

        // Tentar mapear a categoria sugerida pela IA para uma categoria
        // existente. IMPORTANTE: se não houver correspondência clara, NUNCA
        // aplicamos silenciosamente "_categorias.first" — isso já causou
        // classificações "falsas" (uma categoria arbitrária, sem relação
        // nenhuma com a foto, era escolhida sempre que o nome da IA não
        // batia certo com o da BD). Em vez disso: caímos para "Outro" (uma
        // categoria neutra que existe mesmo) e abrimos os ajustes manuais
        // para o utilizador confirmar.
        Categoria? matched;
        if (_categorias.isNotEmpty) {
          for (final c in _categorias) {
            final nomeIA = aiResult.categoriaSugerida.toLowerCase();
            final nomeCat = c.nome.toLowerCase();
            if (nomeCat.contains(nomeIA) || nomeIA.contains(nomeCat)) {
              matched = c;
              break;
            }
          }
        }

        final semCorrespondencia = matched == null;
        if (semCorrespondencia && _categorias.isNotEmpty) {
          matched = _categorias.firstWhere(
            (c) => c.nome.toLowerCase().contains('outro'),
            orElse: () => _categorias.first,
          );
        }

        if (matched != null) {
          _selectedCategoria = matched;
          _aiOriginalCategoria = matched;
        }

        // Foto sem resíduos claramente visíveis, ou sem categoria
        // correspondente: não confiamos na sugestão automática — abre os
        // ajustes manuais desde já, para o utilizador rever/corrigir.
        if (!aiResult.residuoDetectado || semCorrespondencia) {
          _showManualInputs = true;
        }
      }
    } catch (e) {
      debugPrint('Erro ao classificar imagem com Gemini: $e');
    } finally {
      if (mounted) {
        setState(() => _isAnalyzingAI = false);
      }
    }
  }

  void _showPermissionDeniedDialog(String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.shieldAlert, color: AppColors.error),
            const SizedBox(width: 8),
            Text('Permissão de $feature',
                style: const TextStyle(fontFamily: 'Geist', fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Para registar uma ocorrência georreferenciada é necessária a permissão de $feature. Ative nas configurações do sistema.',
          style: const TextStyle(fontFamily: 'Geist', fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(fontFamily: 'Geist')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Abrir Configurações', style: TextStyle(fontFamily: 'Geist')),
          ),
        ],
      ),
    );
  }

  Future<void> _capturePhoto() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      _showPermissionDeniedDialog('Câmara');
      return;
    }

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (photo == null) return;

    setState(() => _imagePath = photo.path);
    await _resolveLocation();
    await _runAIClassification(photo.path);
  }

  Future<void> _resolveLocation() async {
    setState(() {
      _resolvingLocation = true;
      _locationError = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Ative a localização (GPS) do dispositivo.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedDialog('Localização');
        throw 'Permissão de localização negada permanentemente.';
      }
      if (permission == LocationPermission.denied) {
        throw 'Permissão de localização necessária para denunciar.';
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      final inside = BeiraGeo.isInsideBeira(latLng);

      if (!mounted) return;
      setState(() {
        _location = latLng;
        _locationAccuracy = pos.accuracy;
        _locationInsideBeira = inside;
        _resolvingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resolvingLocation = false;
        _locationError = e.toString();
      });
    }
  }

  bool get _canSubmit =>
      _imagePath != null &&
      _location != null &&
      _locationInsideBeira &&
      _selectedCategoria != null &&
      !_controller.isSubmitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final draft = DenunciaDraft(
      id: const Uuid().v4(),
      latitude: _location!.latitude,
      longitude: _location!.longitude,
      descricao: _descricaoController.text.trim().isEmpty
          ? null
          : _descricaoController.text.trim(),
      idCategoria: _selectedCategoria!.id,
      gravidade: _gravidade,
      fotoPathLocal: _imagePath!,
      dataHoraRegisto: DateTime.now(),
    );

    await _controller.submit(
      draft: draft,
      sourceImagePath: _imagePath!,
      isOnline: widget.isOnline,
    );

    if (!mounted) return;
    switch (_controller.status) {
      case DenunciaStatus.sentOnline:
        Navigator.of(context).pop(DenunciaResult.sentOnline);
      case DenunciaStatus.queuedOffline:
        Navigator.of(context).pop(DenunciaResult.queuedOffline);
      case DenunciaStatus.error:
        _showSnack(
          _controller.errorMessage ?? 'Ocorreu um erro.',
          isError: true,
        );
      default:
        break;
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Geist')),
        backgroundColor: isError ? AppColors.error : AppColors.forestGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Nova Denúncia',
          style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPhotoSection(isDark),
                const SizedBox(height: 20),
                if (_imagePath != null) ...[
                  _buildAIResultCard(isDark),
                  const SizedBox(height: 20),
                  _buildLocationSection(isDark),
                  const SizedBox(height: 20),
                  if (!widget.isOnline || _aiResult == null || _showManualInputs) ...[
                    _buildCategoriaSection(isDark, theme),
                    const SizedBox(height: 20),
                    _buildGravidadeSection(isDark),
                    const SizedBox(height: 20),
                    _buildDescricaoSection(isDark),
                    const SizedBox(height: 28),
                  ] else ...[
                    _buildAutoFilledSummaryCard(isDark),
                    const SizedBox(height: 28),
                  ],
                  _buildSubmitButton(isDark),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAutoFilledSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : AppColors.forestGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.forestGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.checkCircle2, color: AppColors.forestGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Preenchido Automaticamente pela IA',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forestGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  'Categoria',
                  _selectedCategoria?.nome ?? 'Outro',
                  LucideIcons.trash2,
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryTile(
                  'Gravidade',
                  _gravidade.label,
                  LucideIcons.alertTriangle,
                  isDark,
                ),
              ),
            ],
          ),
          if (_descricaoController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Descrição Gerada:',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : AppColors.grey700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _descricaoController.text,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12.5,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryTile(String title, String val, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.grey700 : AppColors.grey200,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.forestGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 10.5,
                    color: AppColors.grey600,
                  ),
                ),
                Text(
                  val,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIResultCard(bool isDark) {
    if (_isAnalyzingAI) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? DarkColors.surface : AppColors.grey50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.forestGreen.withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.forestGreen,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'A Xeni está a analisar a foto com IA (Gemini)...',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forestGreen,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!widget.isOnline) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.wifiOff, size: 18, color: AppColors.warning),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Modo Offline: Análise de IA indisponível. As categorias padrão locais foram carregadas para o formulário abaixo.',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_aiResult == null) return const SizedBox.shrink();

    final percent = (_aiResult!.confianca * 100).round();
    final Color confColor;
    if (percent >= 80) {
      confColor = const Color(0xFF2E7D32);
    } else if (percent >= 50) {
      confColor = const Color(0xFFF57F17);
    } else {
      confColor = const Color(0xFFD32F2F);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : AppColors.forestGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.forestGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, size: 18, color: AppColors.forestGreen),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Análise Automática por IA (Xeni)',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forestGreen,
                  ),
                ),
              ),
              // Badge de Grau de Confiança (%) - RF-010
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: confColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: confColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '$percent% Confiança',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: confColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _aiResult!.explicacao,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 12.5,
              color: isDark ? Colors.white70 : AppColors.grey800,
            ),
          ),
          if (!_aiResult!.residuoDetectado) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.alertTriangle, size: 15, color: Color(0xFFD32F2F)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Não conseguimos identificar resíduos com clareza nesta fotografia. Reveja a categoria e a gravidade manualmente antes de submeter.',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD32F2F),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_isManualCorrectionApplied) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Correção manual ativa (RN-005)',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const Expanded(
                  child: Text(
                    'Dados preenchidos pela IA.',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.grey600,
                    ),
                  ),
                ),
              ],
              TextButton.icon(
                onPressed: () => setState(() => _showManualInputs = !_showManualInputs),
                icon: Icon(
                  _showManualInputs ? LucideIcons.chevronUp : LucideIcons.slidersHorizontal,
                  size: 14,
                  color: AppColors.forestGreen,
                ),
                label: Text(
                  _showManualInputs ? 'Ocultar Ajustes' : 'Ajustar / Editar',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forestGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(bool isDark) {
    if (_imagePath == null) {
      return GestureDetector(
        onTap: _capturePhoto,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: isDark ? DarkColors.surface : AppColors.grey50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.forestGreen.withValues(alpha: 0.4),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.camera,
                  size: 40, color: AppColors.forestGreen),
              const SizedBox(height: 12),
              Text(
                'Tocar para fotografar o resíduo',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.grey800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            File(_imagePath!),
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: Material(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _capturePhoto,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.refreshCw, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Repetir',
                        style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 12,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(bool isDark) {
    final Color color;
    final IconData icon;
    final String text;

    if (_resolvingLocation) {
      color = AppColors.grey600;
      icon = LucideIcons.loaderCircle;
      text = 'A obter a sua localização...';
    } else if (_locationError != null) {
      color = AppColors.error;
      icon = LucideIcons.circleAlert;
      text = _locationError!;
    } else if (_location != null && !_locationInsideBeira) {
      color = AppColors.error;
      icon = LucideIcons.mapPinOff;
      text = 'Localização fora da área da Beira. Não é possível denunciar aqui.';
    } else if (_location != null) {
      color = AppColors.success;
      icon = LucideIcons.mapPin;
      final accStr = _locationAccuracy != null ? ' (Precisão: ±${_locationAccuracy!.toStringAsFixed(1)}m)' : '';
      text = 'Localização confirmada na Beira$accStr.';
    } else {
      color = AppColors.grey600;
      icon = LucideIcons.mapPin;
      text = 'Localização por confirmar.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          if (_locationError != null || (_location != null && !_locationInsideBeira))
            TextButton(
              onPressed: _resolveLocation,
              child: const Text('Tentar',
                  style: TextStyle(fontFamily: 'Geist', fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriaSection(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Tipo de resíduo', isDark),
        const SizedBox(height: 8),
        DropdownButtonFormField<Categoria>(
          initialValue: _selectedCategoria,
          isExpanded: true,
          dropdownColor: isDark ? DarkColors.surface : AppColors.white,
          hint: Text(
            _categorias.isEmpty
                ? 'Sem categorias (ligue-se à internet uma vez)'
                : 'Selecione o tipo',
            style: const TextStyle(fontFamily: 'Geist', color: AppColors.grey600),
          ),
          decoration: _inputDecoration(isDark, LucideIcons.trash2),
          items: _categorias
              .map((c) => DropdownMenuItem(value: c, child: Text(c.nome)))
              .toList(),
          onChanged: (v) => setState(() => _selectedCategoria = v),
        ),
      ],
    );
  }

  Widget _buildGravidadeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Gravidade', isDark),
        const SizedBox(height: 8),
        Row(
          children: Gravidade.values.map((g) {
            final selected = g == _gravidade;
            final color = _gravidadeColor(g);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: g == Gravidade.critica ? 0 : 8),
                child: GestureDetector(
                  onTap: () => setState(() => _gravidade = g),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.16)
                          : (isDark ? DarkColors.surface : AppColors.grey50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        g.label,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 12.5,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.w500,
                          color: selected
                              ? color
                              : (isDark ? Colors.white70 : AppColors.grey800),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescricaoSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Descrição (opcional)', isDark),
        const SizedBox(height: 8),
        TextField(
          controller: _descricaoController,
          maxLines: 3,
          style: TextStyle(
            fontFamily: 'Geist',
            color: isDark ? Colors.white : AppColors.grey900,
          ),
          decoration: _inputDecoration(isDark, LucideIcons.fileText).copyWith(
            hintText: 'Ex: entulho na berma há vários dias',
            hintStyle: const TextStyle(
                fontFamily: 'Geist', color: AppColors.grey600, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return ElevatedButton(
      onPressed: _canSubmit ? _submit : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            isDark ? AppColors.grey800 : AppColors.grey300,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: _controller.isSubmitting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Text(
              widget.isOnline ? 'Enviar denúncia' : 'Guardar (offline)',
              style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _label(String text, bool isDark) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.forestGreen,
        ),
      );

  InputDecoration _inputDecoration(bool isDark, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon,
          size: 20,
          color: isDark ? AppColors.sageGreen : AppColors.forestGreen),
      filled: true,
      fillColor: isDark ? DarkColors.surface : AppColors.grey50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Color _gravidadeColor(Gravidade g) {
    switch (g) {
      case Gravidade.baixa:
        return const Color(0xFF2E9E5B);
      case Gravidade.media:
        return const Color(0xFFF57C00);
      case Gravidade.alta:
        return const Color(0xFFEF6C00);
      case Gravidade.critica:
        return const Color(0xFFE53935);
    }
  }
}
