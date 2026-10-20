import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/beira_neighborhoods.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../map/data/reverse_geocoder.dart';
import '../../../occurrence/data/resolucao_datasource.dart';
import '../../../occurrence/domain/resolucao_verificacao.dart';
import '../../../occurrence/presentation/pages/resolucao_verification_page.dart';
import '../../../profile/domain/my_report.dart';

/// Detalhe em ecrã cheio de uma ocorrência: foto grande, descrição completa,
/// estado, gravidade, data, coordenadas e bairro (geocodificação inversa).
class ReportDetailPage extends StatefulWidget {
  final MyReport report;

  const ReportDetailPage({super.key, required this.report});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  String? _bairro;
  bool _resolvingBairro = true;

  ResolucaoVerificacao? _verificacao;
  bool _loadingVerificacao = false;

  @override
  void initState() {
    super.initState();
    _resolveBairro();
    if (_isResolvidoOuEmVerificacao()) {
      _loadVerificacao();
    }
  }

  bool _isResolvidoOuEmVerificacao() {
    final e = widget.report.estado.toLowerCase();
    return e == 'resolvido' ||
        e == 'resolvida' ||
        e == 'em_verificacao' ||
        e == 'concluido';
  }

  Future<void> _loadVerificacao() async {
    setState(() => _loadingVerificacao = true);
    try {
      final res =
          await ResolucaoDataSource().fetchVerificacao(widget.report.id);
      if (!mounted) return;
      setState(() {
        _verificacao = res;
        _loadingVerificacao = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingVerificacao = false);
    }
  }

  /// Converte as coordenadas num nome de zona/bairro. É best-effort e depende de
  /// rede; em falha faz fallback instantâneo para BeiraNeighborhoods.
  Future<void> _resolveBairro() async {
    String? nome;
    try {
      nome = await ReverseGeocoder.bairro(
        widget.report.latitude,
        widget.report.longitude,
      );
    } catch (_) {}

    nome ??= BeiraNeighborhoods.findClosestBairro(
      widget.report.latitude,
      widget.report.longitude,
    );

    if (!mounted) return;
    setState(() {
      _bairro = nome;
      _resolvingBairro = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.grey900 : const Color(0xFFF4F2EB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Foto grande no topo com o botão de voltar sobreposto.
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: isDark ? DarkColors.surface : AppColors.forestGreen,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                child: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _photo(isDark),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.categoria,
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.grey900,
                          ),
                        ),
                      ),
                      _estadoBadge(report),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gravidade: ${report.gravidadeLabel}',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('Descrição', isDark),
                  const SizedBox(height: 6),
                  Text(
                    report.descricao,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14.5,
                      height: 1.5,
                      color: isDark ? Colors.white70 : AppColors.grey800,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionLabel('Localização', isDark),
                  const SizedBox(height: 10),
                  _infoRow(
                    isDark,
                    icon: LucideIcons.mapPin,
                    label: 'Bairro',
                    value: _resolvingBairro
                        ? 'A localizar...'
                        : (_bairro ?? 'Não identificado'),
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    isDark,
                    icon: LucideIcons.locateFixed,
                    label: 'Coordenadas',
                    value: report.coordenadas,
                  ),
                  const SizedBox(height: 22),
                  _sectionLabel('Registo', isDark),
                  const SizedBox(height: 10),
                  _infoRow(
                    isDark,
                    icon: LucideIcons.calendar,
                    label: 'Data',
                    value: report.dataFormatada,
                  ),
                  if (_isResolvidoOuEmVerificacao())
                    _buildAnexosResolucaoSection(isDark),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnexosResolucaoSection(bool isDark) {
    if (_loadingVerificacao) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            color: isDark ? DarkColors.accent : AppColors.forestGreen,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final ver = _verificacao;
    if (ver == null) return const SizedBox.shrink();

    final temFotoResolucao =
        ver.fotoResolucaoUrl != null && ver.fotoResolucaoUrl!.isNotEmpty;
    final obs = ver.observacoesEquipa;

    return Container(
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? DarkColors.accent.withValues(alpha: 0.3)
              : AppColors.sageGreen.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.paperclip,
                size: 18,
                color: isDark ? DarkColors.accent : AppColors.forestGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ANEXOS DA RESOLUÇÃO',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isDark ? DarkColors.accent : AppColors.forestGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (temFotoResolucao) ...[
            Text(
              'Foto da Limpeza / Intervenção Realizada:',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppColors.grey800,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildResolucaoImage(ver.fotoResolucaoUrl!, isDark),
            ),
            const SizedBox(height: 12),
          ],
          if (obs != null && obs.isNotEmpty) ...[
            Text(
              'Observações da Equipa Técnica:',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppColors.grey800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              obs,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13.5,
                height: 1.4,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (ver.dataResolucao != null) ...[
            Row(
              children: [
                Icon(LucideIcons.clock,
                    size: 14,
                    color: isDark ? Colors.white54 : AppColors.grey600),
                const SizedBox(width: 6),
                Text(
                  'Concluído em: ${formatChatDataHora(ver.dataResolucao!)}',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    color: isDark ? Colors.white60 : AppColors.grey600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ResolucaoVerificationPage(
                      occurrenceId: widget.report.id,
                      occurrenceTitle: widget.report.categoria,
                    ),
                  ),
                );
                if (mounted) {
                  _loadVerificacao();
                }
              },
              icon: const Icon(LucideIcons.checkCheck, size: 16),
              label: const Text(
                'Verificar / Confirmar Resolução',
                style: TextStyle(
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? DarkColors.accent : AppColors.forestGreen,
                foregroundColor: isDark ? DarkColors.onAccent : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolucaoImage(String url, bool isDark) {
    final trimmed = url.trim();

    return GestureDetector(
      onTap: () => _showFullScreenImage(trimmed, 'Foto da Resolução'),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey800 : AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildImageWidget(trimmed, isDark),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.maximize2, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Ver ampliado',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String trimmed, bool isDark) {
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final base64Data =
            commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _errorPlaceholder(isDark),
        );
      } catch (e) {
        debugPrint('Erro ao descodificar imagem base64: $e');
        return _errorPlaceholder(isDark);
      }
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      final file = File(trimmed);
      if (file.existsSync()) {
        return Image.file(
          file,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }

    return CachedNetworkImage(
      imageUrl: trimmed,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (ctx, url) => Container(
        height: 180,
        color: isDark ? AppColors.grey800 : AppColors.grey100,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (ctx, url, err) => _errorPlaceholder(isDark),
    );
  }

  Widget _errorPlaceholder(bool isDark) {
    return Container(
      height: 180,
      color: AppColors.forestGreen.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(LucideIcons.imageOff, size: 36, color: AppColors.grey600),
      ),
    );
  }

  void _showFullScreenImage(String url, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildImageWidget(url, isDark),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photo(bool isDark) {
    final url = widget.report.photoUrl;
    if (url == null || url.isEmpty) {
      return Container(
        color: AppColors.forestGreen.withValues(alpha: 0.15),
        child: const Center(
          child: Icon(LucideIcons.image, color: Colors.white70, size: 60),
        ),
      );
    }

    final trimmed = url.trim();

    if (trimmed.startsWith('data:image')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final base64Data =
            commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final bytes = base64Decode(base64Data);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        debugPrint('Erro ao descodificar imagem da ocorrencia: $e');
      }
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      final file = File(trimmed);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    return CachedNetworkImage(
      imageUrl: trimmed,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: isDark ? AppColors.grey800 : AppColors.grey200,
        child: const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.forestGreen.withValues(alpha: 0.15),
        child: const Center(
          child: Icon(LucideIcons.imageOff, color: Colors.white70, size: 50),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? AppColors.sageGreen : AppColors.forestGreen,
        ),
      );

  Widget _infoRow(bool isDark,
      {required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isDark ? Colors.white54 : AppColors.grey600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: isDark ? Colors.white38 : AppColors.grey600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _estadoBadge(MyReport report) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: report.estadoColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: report.estadoColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        report.estadoLabel,
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: report.estadoColor,
        ),
      ),
    );
  }
}
