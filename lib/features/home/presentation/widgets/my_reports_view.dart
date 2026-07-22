import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../../profile/domain/my_report.dart';
import '../pages/report_detail_page.dart';

/// Grelha premium das ocorrências do utilizador: cada card mostra a foto real
/// por cima da descrição, com o estado sobreposto na imagem.
class MyReportsView extends StatefulWidget {
  final List<MyReport> reports;
  final RefreshCallback? onRefresh;
  final VoidCallback? onItemReturned;

  const MyReportsView({
    super.key,
    required this.reports,
    this.onRefresh,
    this.onItemReturned,
  });

  @override
  State<MyReportsView> createState() => _MyReportsViewState();
}

class _MyReportsViewState extends State<MyReportsView> {
  String _searchQuery = '';
  String _selectedFilter = 'Todas';

  static const _filters = ['Todas', 'Pendente', 'Em análise', 'Resolvida'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = widget.reports.where((r) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          r.categoria.toLowerCase().contains(q) ||
          r.descricao.toLowerCase().contains(q);
      final matchesFilter =
          _selectedFilter == 'Todas' || r.estadoLabel == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    final content = Column(
      children: [
        _buildSearchAndFilters(isDark),
        Expanded(
          child: filtered.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: _buildEmptyState(isDark),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 18,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _ReportCard(
                    report: filtered[index],
                    isDark: isDark,
                    onItemReturned: widget.onItemReturned,
                  ),
                ),
        ),
      ],
    );

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        color: AppColors.forestGreen,
        onRefresh: widget.onRefresh!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildSearchAndFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Column(
        children: [
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey900 : AppColors.grey100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.grey800 : AppColors.grey200,
              ),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontFamily: 'Geist', fontSize: 14),
              decoration: const InputDecoration(
                prefixIcon:
                    Icon(LucideIcons.search, color: AppColors.grey600, size: 18),
                hintText: 'Procurar por tipo ou descrição...',
                hintStyle: TextStyle(
                    fontFamily: 'Geist', fontSize: 14, color: AppColors.grey600),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _buildFilterChip(_filters[i], isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final selected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.forestGreen
              : (isDark ? AppColors.grey900 : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.forestGreen
                : (isDark ? AppColors.grey800 : AppColors.grey300),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : AppColors.grey800),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.grey900 : AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.clipboardList,
                  size: 40, color: AppColors.grey600),
            ),
            const SizedBox(height: 16),
            Text(
              widget.reports.isEmpty
                  ? 'Ainda não fez nenhuma denúncia'
                  : 'Nenhuma ocorrência encontrada',
              style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.reports.isEmpty
                  ? 'As suas denúncias aparecem aqui depois de submetidas.'
                  : 'Experimente outro filtro ou pesquisa.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Geist', fontSize: 13, color: AppColors.grey600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final MyReport report;
  final bool isDark;
  final VoidCallback? onItemReturned;

  const _ReportCard({
    required this.report,
    required this.isDark,
    this.onItemReturned,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ReportDetailPage(report: report)),
        );
        onItemReturned?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto por cima, com o estado sobreposto.
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _photo(),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _estadoBadge(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        // Descrição por baixo, sem fundo.
        Text(
          report.categoria,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          flex: 2,
          child: Text(
            report.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 11.5,
              height: 1.3,
              color: isDark ? Colors.white60 : AppColors.grey600,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(LucideIcons.calendar,
                size: 11, color: isDark ? Colors.white38 : AppColors.grey600),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                report.dataFormatada,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 10.5,
                  color: isDark ? Colors.white38 : AppColors.grey600,
                ),
              ),
            ),
          ],
          ),
        ],
        ),
    );
  }

  Widget _photo() {
    if (report.photoUrl == null) {
      return Container(
        color: AppColors.forestGreen.withValues(alpha: 0.1),
        child: const Center(
          child: Icon(LucideIcons.image, color: AppColors.forestGreen, size: 34),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: report.photoUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: isDark ? AppColors.grey800 : AppColors.grey100,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.forestGreen),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.forestGreen.withValues(alpha: 0.1),
        child: const Center(
          child: Icon(LucideIcons.imageOff,
              color: AppColors.forestGreen, size: 30),
        ),
      ),
    );
  }

  Widget _estadoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: report.estadoColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        report.estadoLabel,
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
