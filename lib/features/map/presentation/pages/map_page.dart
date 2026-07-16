import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/occurrence_model.dart';
import '../../domain/ponto_recolha_model.dart';
import '../widgets/txeneza_map.dart';
import '../widgets/pill_toggle.dart';
import '../widgets/heatmap_legend.dart';
import '../widgets/occurrence_sheet.dart';
import '../../../home/presentation/pages/home_screen.dart';

class MapPage extends StatelessWidget {
  final MapMode mapMode;
  final List<Occurrence> occurrences;
  final List<PontoRecolha> pontosRecolha;
  final bool isOnline;
  final MapController mapController;
  final double currentScale;
  final LatLng userLocation;
  final bool isResolvingGps;
  final ValueChanged<double> onScaleChanged;
  final ValueChanged<MapMode> onMapModeToggled;
  final VoidCallback onLocationPressed;
  final VoidCallback onReport;
  final ValueChanged<Occurrence> onOccurrenceSelected;

  const MapPage({
    super.key,
    required this.mapMode,
    required this.occurrences,
    this.pontosRecolha = const [],
    required this.isOnline,
    required this.mapController,
    required this.currentScale,
    required this.userLocation,
    required this.isResolvingGps,
    required this.onScaleChanged,
    required this.onMapModeToggled,
    required this.onLocationPressed,
    required this.onReport,
    required this.onOccurrenceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    const appBarHeight = 72.0;
    final offlineBannerHeight = isOnline ? 0.0 : 48.0;
    final topOffset = statusBarHeight + appBarHeight + offlineBannerHeight + 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Fração recolhida do sheet, adaptada à altura disponível para que
        // o cabeçalho (stats + ação) caiba sem cortar em ecrãs pequenos.
        final double collapsedSize =
            (196.0 / constraints.maxHeight).clamp(0.18, 0.34);
        final double collapsedPx = collapsedSize * constraints.maxHeight;

        return Stack(
          children: [
            // Mapa a preencher toda a área.
            Positioned.fill(
              child: TxenezaMap(
                mapMode: mapMode,
                occurrences: occurrences,
                pontosRecolha: pontosRecolha,
                showClusters: currentScale < 12.0,
                currentScale: currentScale,
                mapController: mapController,
                userLocation: userLocation,
                isResolvingGps: isResolvingGps,
                onScaleChanged: onScaleChanged,
              ),
            ),

            // Alternador Mapa / Calor.
            Positioned(
              top: topOffset,
              right: 16,
              child: PillToggle(
                mapMode: mapMode,
                onChanged: onMapModeToggled,
              ),
            ),

            // Legenda do mapa de calor, ancorada acima do sheet recolhido.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: mapMode == MapMode.heatmap ? collapsedPx + 16 : -140,
              left: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: mapMode == MapMode.heatmap ? 1.0 : 0.0,
                child: const HeatmapLegend(),
              ),
            ),

            // Botão de localização GPS, também acima do sheet recolhido.
            Positioned(
              bottom: collapsedPx + 16,
              right: 16,
              child: FloatingLocationButton(
                isResolving: isResolvingGps,
                onPressed: onLocationPressed,
              ),
            ),

            // Painel inferior arrastável com resumo e lista.
            OccurrenceSheet(
              occurrences: occurrences,
              mapMode: mapMode,
              isOnline: isOnline,
              onReport: onReport,
              onOccurrenceTap: onOccurrenceSelected,
              collapsedSize: collapsedSize,
            ),
          ],
        );
      },
    );
  }
}
