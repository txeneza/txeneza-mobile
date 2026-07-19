import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/occurrence_model.dart';
import '../../domain/ponto_recolha_model.dart';
import '../widgets/txeneza_map.dart';
import '../widgets/occurrence_sheet.dart';
import '../../../home/presentation/pages/home_screen.dart';

class MapPage extends StatelessWidget {
  final List<Occurrence> occurrences;
  final List<PontoRecolha> pontosRecolha;
  final bool isOnline;
  final void Function(MapboxMap) onMapCreated;
  final double currentScale;
  final LatLng userLocation;
  final bool isResolvingGps;
  final ValueChanged<double> onScaleChanged;
  final VoidCallback onLocationPressed;
  final VoidCallback onReport;
  final ValueChanged<Occurrence> onOccurrenceSelected;
  final bool showPontosRecolha;
  final ValueChanged<bool> onShowPontosRecolhaToggled;

  const MapPage({
    super.key,
    required this.occurrences,
    this.pontosRecolha = const [],
    required this.isOnline,
    required this.onMapCreated,
    required this.currentScale,
    required this.userLocation,
    required this.isResolvingGps,
    required this.onScaleChanged,
    required this.onLocationPressed,
    required this.onReport,
    required this.onOccurrenceSelected,
    required this.showPontosRecolha,
    required this.onShowPontosRecolhaToggled,
  });

  @override
  Widget build(BuildContext context) {
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
                mapMode: MapMode.normal,
                occurrences: occurrences,
                pontosRecolha: pontosRecolha,
                showClusters: currentScale < 12.0,
                currentScale: currentScale,
                onMapCreated: onMapCreated,
                userLocation: userLocation,
                isResolvingGps: isResolvingGps,
                onScaleChanged: onScaleChanged,
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
              isOnline: isOnline,
              onReport: onReport,
              onOccurrenceTap: onOccurrenceSelected,
              collapsedSize: collapsedSize,
              showPontosRecolha: showPontosRecolha,
              onShowPontosRecolhaToggled: onShowPontosRecolhaToggled,
            ),
          ],
        );
      },
    );
  }
}
