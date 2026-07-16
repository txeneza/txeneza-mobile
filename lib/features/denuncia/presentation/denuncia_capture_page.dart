import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/colors/app_colors.dart';
import '../../../core/theme/colors/dark_colors.dart';
import '../../map/domain/beira_geo.dart';
import '../data/categoria_datasource.dart';
import '../domain/categoria.dart';
import '../domain/denuncia_draft.dart';
import '../domain/gravidade.dart';
import 'denuncia_controller.dart';

/// Resultado devolvido ao fechar a página, para a home saber o que aconteceu.
enum DenunciaResult { sentOnline, queuedOffline }

/// Fluxo de captura de denúncia: foto → GPS + validação Beira → categoria +
/// gravidade → submeter (online ou fila offline).
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
  final _descricaoController = TextEditingController();
  final _picker = ImagePicker();

  String? _imagePath;
  LatLng? _location;
  bool _locationInsideBeira = false;
  bool _resolvingLocation = false;
  String? _locationError;

  List<Categoria> _categorias = [];
  Categoria? _selectedCategoria;
  Gravidade _gravidade = Gravidade.media;

  @override
  void initState() {
    super.initState();
    _loadCategorias();
    // Foto recuperada após o Android ter matado a app durante a câmara.
    if (widget.initialImagePath != null) {
      _imagePath = widget.initialImagePath;
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolveLocation());
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
      setState(() => _categorias = cats);
    } catch (_) {
      // Sem rede e sem cache: o utilizador verá o aviso no dropdown.
    }
  }

  Future<void> _capturePhoto() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      _showSnack('Permissão de câmara necessária para denunciar.', isError: true);
      return;
    }

    // Limites conservadores: reduzem a memória usada e a probabilidade de o
    // Android matar a app enquanto a câmara está aberta (dispositivos fracos).
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (photo == null) return;

    setState(() => _imagePath = photo.path);
    await _resolveLocation();
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
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
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
                  _buildLocationSection(isDark),
                  const SizedBox(height: 20),
                  _buildCategoriaSection(isDark, theme),
                  const SizedBox(height: 20),
                  _buildGravidadeSection(isDark),
                  const SizedBox(height: 20),
                  _buildDescricaoSection(isDark),
                  const SizedBox(height: 28),
                  _buildSubmitButton(isDark),
                ],
              ],
            ),
          );
        },
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
      text = 'Localização confirmada dentro da Beira.';
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
