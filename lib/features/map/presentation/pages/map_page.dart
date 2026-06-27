import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/colors/app_colors.dart';
import '../../../../core/theme/spacing/app_spacing.dart';
import '../../../../core/theme/spacing/app_radius.dart';
import '../../domain/occurrence_model.dart';
import '../widgets/txeneza_map.dart';
import '../widgets/pill_toggle.dart';
import '../widgets/heatmap_legend.dart';
import '../../../home/presentation/pages/home_screen.dart';

class MapPage extends StatelessWidget {
  final MapMode mapMode;
  final List<Occurrence> occurrences;
  final bool isOnline;
  final MapController mapController;
  final double currentScale;
  final LatLng userLocation;
  final bool isResolvingGps;
  final ValueChanged<double> onScaleChanged;
  final ValueChanged<MapMode> onMapModeToggled;
  final VoidCallback onLocationPressed;

  const MapPage({
    super.key,
    required this.mapMode,
    required this.occurrences,
    required this.isOnline,
    required this.mapController,
    required this.currentScale,
    required this.userLocation,
    required this.isResolvingGps,
    required this.onScaleChanged,
    required this.onMapModeToggled,
    required this.onLocationPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final appBarHeight = 72.0;
    final offlineBannerHeight = isOnline ? 0.0 : 48.0;
    final topOffset = statusBarHeight + appBarHeight + offlineBannerHeight + 12.0;

    return Column(
      children: [
        // 70% Map view
        Expanded(
          flex: 7,
          child: Stack(
            children: [
              TxenezaMap(
                mapMode: mapMode,
                occurrences: occurrences,
                showClusters: currentScale < 12.0,
                currentScale: currentScale,
                mapController: mapController,
                userLocation: userLocation,
                isResolvingGps: isResolvingGps,
                onScaleChanged: onScaleChanged,
              ),

              // Floating Toggle (Mapa vs Calor)
              Positioned(
                top: topOffset,
                right: 16,
                child: PillToggle(
                  mapMode: mapMode,
                  onChanged: onMapModeToggled,
                ),
              ),

              // Heatmap Legend overlay
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                bottom: mapMode == MapMode.heatmap ? 16 : -100,
                left: 16,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: mapMode == MapMode.heatmap ? 1.0 : 0.0,
                  child: const HeatmapLegend(),
                ),
              ),

              // GPS Locate Button
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingLocationButton(
                  isResolving: isResolvingGps,
                  onPressed: onLocationPressed,
                ),
              ),
            ],
          ),
        ),

        // 30% Bottom Details Panel
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey900 : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mapMode == MapMode.heatmap 
                          ? 'Zonas Críticas de Resíduos' 
                          : 'Painel de Saneamento - Beira',
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    // Quick Status Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOnline 
                            ? AppColors.mintGreen.withValues(alpha: 0.3)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOnline ? AppColors.success : const Color(0xFFFFB300),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline ? 'Tempo Real' : 'Dados Locais',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isOnline ? AppColors.success : const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  mapMode == MapMode.heatmap
                      ? 'Visualizando mapa de calor com base nas ocorrências ativas. As áreas em vermelho indicam alta densidade de resíduos acumulados.'
                      : 'Utilize o mapa acima para reportar e rastrear pontos de descarte irregular de lixo pela cidade.',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: AppColors.grey800,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                // Sync information bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.black : AppColors.grey50,
                    borderRadius: AppRadius.borderSM,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.refreshCw,
                        size: 13,
                        color: AppColors.grey600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isOnline
                              ? 'Pontos sincronizados em tempo real (${occurrences.length} ativos)'
                              : 'Sincronizado pela última vez: Hoje às 06:45 (${occurrences.length} salvos)',
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 11,
                            color: AppColors.grey600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
