import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../../../core/theme/spacing/app_radius.dart';
import '../../../map/domain/occurrence_model.dart';

class MyReportsView extends StatefulWidget {
  final List<Occurrence> occurrences;
  final double topPadding;

  const MyReportsView({
    super.key,
    required this.occurrences,
    this.topPadding = 0.0,
  });

  @override
  State<MyReportsView> createState() => _MyReportsViewState();
}

class _MyReportsViewState extends State<MyReportsView> {
  String _searchQuery = '';
  String _selectedStatus = 'Todos';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter occurrences based on selectedStatus and searchQuery
    final filteredList = widget.occurrences.where((occ) {
      final matchesSearch = occ.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          occ.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = switch (_selectedStatus) {
        'Todos' => true,
        'Pendentes' => occ.status == OccurrenceStatus.pending,
        'Críticos' => occ.status == OccurrenceStatus.critical,
        'Resolvidos' => occ.status == OccurrenceStatus.resolved,
        _ => true,
      };

      return matchesSearch && matchesStatus;
    }).toList();

    return Column(
      children: [
        if (widget.topPadding > 0) SizedBox(height: widget.topPadding),
        // Search & Filter Header
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.grey900 : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.grey800 : AppColors.grey200,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Search Field
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.black : AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.grey800 : AppColors.grey300,
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: const TextStyle(fontFamily: 'Geist', fontSize: 14),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      LucideIcons.search,
                      color: AppColors.grey600,
                      size: 18,
                    ),
                    hintText: 'Buscar denúncia...',
                    hintStyle: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      color: AppColors.grey600,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Status Filters Scroll View
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('Todos'),
                    _buildFilterChip('Pendentes'),
                    _buildFilterChip('Críticos'),
                    _buildFilterChip('Resolvidos'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Reports List View
        Expanded(
          child: filteredList.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: filteredList.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final occ = filteredList[index];
                    return _buildOccurrenceCard(occ, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedStatus == label;
    final theme = Theme.of(context);

    // Resolve color for selected states
    final Color selectedBgColor = switch (label) {
      'Pendentes' => const Color(0xFFFB8C00).withValues(alpha: 0.15),
      'Críticos' => const Color(0xFFE53935).withValues(alpha: 0.15),
      'Resolvidos' => const Color(0xFF43A047).withValues(alpha: 0.15),
      _ => AppColors.forestGreen.withValues(alpha: 0.15),
    };

    final Color selectedTextColor = switch (label) {
      'Pendentes' => const Color(0xFFE65100),
      'Críticos' => const Color(0xFFB71C1C),
      'Resolvidos' => const Color(0xFF1B5E20),
      _ => AppColors.forestGreen,
    };

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStatus = label;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? selectedBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? selectedTextColor.withValues(alpha: 0.4)
                  : (theme.brightness == Brightness.dark ? AppColors.grey800 : AppColors.grey300),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? selectedTextColor : AppColors.grey800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOccurrenceCard(Occurrence occ, bool isDark) {
    final statusColor = switch (occ.status) {
      OccurrenceStatus.critical => const Color(0xFFE53935),
      OccurrenceStatus.pending => const Color(0xFFFB8C00),
      OccurrenceStatus.resolved => const Color(0xFF43A047),
    };

    final statusLabel = switch (occ.status) {
      OccurrenceStatus.critical => 'Crítico',
      OccurrenceStatus.pending => 'Pendente',
      OccurrenceStatus.resolved => 'Resolvido',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey900 : Colors.white,
        borderRadius: AppRadius.borderMD,
        border: Border.all(
          color: isDark ? AppColors.grey800 : AppColors.grey200,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderMD,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Indicator Left Border
              Container(
                width: 5,
                color: statusColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              occ.title,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.25),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        occ.description,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13,
                          color: AppColors.grey600,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 12,
                            color: AppColors.grey600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Coordenadas: ${occ.position.latitude.toStringAsFixed(4)}, ${occ.position.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 11,
                                color: AppColors.grey600,
                              ),
                            ),
                          ),
                          Text(
                            occ.status == OccurrenceStatus.resolved ? 'Resolvido há 1d' : 'Criado há 3d',
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 11,
                              color: AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
              child: const Icon(
                LucideIcons.fileSpreadsheet,
                size: 40,
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma denúncia encontrada',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Experimente alterar os filtros de status ou fazer uma nova pesquisa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
