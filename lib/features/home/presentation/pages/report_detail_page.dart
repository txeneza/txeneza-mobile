import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../../map/data/reverse_geocoder.dart';
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

  @override
  void initState() {
    super.initState();
    _resolveBairro();
  }

  /// Converte as coordenadas num nome de zona/bairro. É best-effort e depende de
  /// rede; em falha mostramos apenas as coordenadas.
  Future<void> _resolveBairro() async {
    final nome = await ReverseGeocoder.bairro(
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
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photo(bool isDark) {
    if (widget.report.photoUrl == null) {
      return Container(
        color: AppColors.forestGreen.withValues(alpha: 0.15),
        child: const Center(
          child: Icon(LucideIcons.image, color: Colors.white70, size: 60),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: widget.report.photoUrl!,
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
