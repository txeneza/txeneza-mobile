import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/colors/dark_colors.dart';
import '../../domain/occurrence_model.dart';
import 'occurrence_marker_widget.dart';

/// Painel inferior arrastável (estilo mapas premium) com resumo por estado,
/// ação primária de denúncia e lista interativa de ocorrências.
class OccurrenceSheet extends StatelessWidget {
  final List<Occurrence> occurrences;
  final bool isOnline;
  final VoidCallback onReport;
  final ValueChanged<Occurrence> onOccurrenceTap;

  /// Fração da altura disponível ocupada quando recolhido.
  final double collapsedSize;
  final bool showPontosRecolha;
  final ValueChanged<bool> onShowPontosRecolhaToggled;

  const OccurrenceSheet({
    super.key,
    required this.occurrences,
    required this.isOnline,
    required this.onReport,
    required this.onOccurrenceTap,
    required this.collapsedSize,
    required this.showPontosRecolha,
    required this.onShowPontosRecolhaToggled,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? DarkColors.surface : Colors.white;

    final criticas =
        occurrences.where((o) => o.status == OccurrenceStatus.critical).length;
    final pendentes =
        occurrences.where((o) => o.status == OccurrenceStatus.pending).length;
    final resolvidas =
        occurrences.where((o) => o.status == OccurrenceStatus.resolved).length;

    return DraggableScrollableSheet(
      initialChildSize: collapsedSize,
      minChildSize: collapsedSize,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: [collapsedSize, 0.55, 0.9],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  isDark: isDark,
                  isOnline: isOnline,
                  criticas: criticas,
                  pendentes: pendentes,
                  resolvidas: resolvidas,
                  onReport: onReport,
                  showPontosRecolha: showPontosRecolha,
                  onShowPontosRecolhaToggled: onShowPontosRecolhaToggled,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final occ = occurrences[index];
                    return _OccurrenceCard(
                      occurrence: occ,
                      isDark: isDark,
                      onTap: () => onOccurrenceTap(occ),
                    );
                  },
                  childCount: occurrences.length,
                ),
              ),
              // Espaço final para os últimos cartões não ficarem sob o FAB/nav.
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final bool isDark;
  final bool isOnline;
  final int criticas;
  final int pendentes;
  final int resolvidas;
  final VoidCallback onReport;
  final bool showPontosRecolha;
  final ValueChanged<bool> onShowPontosRecolhaToggled;

  const _Header({
    required this.isDark,
    required this.isOnline,
    required this.criticas,
    required this.pendentes,
    required this.resolvidas,
    required this.onReport,
    required this.showPontosRecolha,
    required this.onShowPontosRecolhaToggled,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : AppColors.forestGreen;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pega de arraste.
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Título + estado de sincronização + ação primária.
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minhas Ocorrências',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _SyncBadge(isOnline: isOnline),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.white38 : AppColors.grey300,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => onShowPontosRecolhaToggled(!showPontosRecolha),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                showPontosRecolha ? LucideIcons.eye : LucideIcons.eyeOff,
                                size: 13,
                                color: showPontosRecolha ? AppColors.forestGreen : AppColors.grey600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Pontos de Recolha',
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: showPontosRecolha ? AppColors.forestGreen : AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ReportButton(onTap: onReport),
            ],
          ),
          const SizedBox(height: 16),

          // Resumo por estado.
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  color: occurrenceStatusColor(OccurrenceStatus.critical),
                  count: criticas,
                  label: 'Críticas',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatPill(
                  color: occurrenceStatusColor(OccurrenceStatus.pending),
                  count: pendentes,
                  label: 'Pendentes',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatPill(
                  color: occurrenceStatusColor(OccurrenceStatus.resolved),
                  count: resolvidas,
                  label: 'Resolvidas',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  final bool isOnline;
  const _SyncBadge({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppColors.success : const Color(0xFFE65100);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          isOnline ? 'Tempo real' : 'Dados locais',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ReportButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ReportButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.forestGreen,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.camera, color: Colors.white, size: 16),
              SizedBox(width: 7),
              Text(
                'Denunciar',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final Color color;
  final int count;
  final String label;
  final bool isDark;

  const _StatPill({
    required this.color,
    required this.count,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.grey800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OccurrenceCard extends StatelessWidget {
  final Occurrence occurrence;
  final bool isDark;
  final VoidCallback onTap;

  const _OccurrenceCard({
    required this.occurrence,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = occurrenceStatusColor(occurrence.status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Material(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Miniatura da fotografia da denúncia, com um selo de
                // estado sobreposto no canto. Sem foto (não devia acontecer
                // nas ocorrências novas, mas por segurança), cai para o
                // círculo de ícone antigo.
                _OccurrenceThumbnail(occurrence: occurrence, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        occurrence.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        occurrence.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 12,
                          height: 1.35,
                          color: isDark ? Colors.white60 : AppColors.grey600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _StatusChip(status: occurrence.status),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: isDark ? Colors.white38 : AppColors.grey600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OccurrenceThumbnail extends StatelessWidget {
  final Occurrence occurrence;
  final Color color;

  const _OccurrenceThumbnail({required this.occurrence, required this.color});

  @override
  Widget build(BuildContext context) {
    final photoUrl = occurrence.photoUrl;

    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: photoUrl == null || photoUrl.isEmpty
                ? Container(
                    width: 42,
                    height: 42,
                    color: color.withValues(alpha: 0.14),
                    child: Icon(
                      occurrenceStatusIcon(occurrence.status),
                      size: 19,
                      color: color,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: photoUrl,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 42,
                      height: 42,
                      color: AppColors.grey200,
                      child: const Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.forestGreen),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 42,
                      height: 42,
                      color: color.withValues(alpha: 0.14),
                      child: Icon(
                        occurrenceStatusIcon(occurrence.status),
                        size: 19,
                        color: color,
                      ),
                    ),
                  ),
          ),
          // Selo de estado no canto — continua visível mesmo com foto.
          Positioned(
            bottom: -3,
            right: -3,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(
                occurrenceStatusIcon(occurrence.status),
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OccurrenceStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = occurrenceStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        occurrenceStatusLabel(status),
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
