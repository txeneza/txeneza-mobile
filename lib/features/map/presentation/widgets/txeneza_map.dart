import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/config/env/app_env.dart';
import '../../domain/occurrence_model.dart';
import 'occurrence_marker_widget.dart';

enum MapMode { normal, satellite, heatmap }

class TxenezaMap extends StatefulWidget {
  final MapMode mapMode;
  final List<Occurrence> occurrences;
  final bool showClusters;
  final double currentScale; // Used as current zoom level
  final MapController mapController;
  final LatLng? userLocation;
  final bool isResolvingGps;
  final ValueChanged<double> onScaleChanged;

  const TxenezaMap({
    super.key,
    required this.mapMode,
    required this.occurrences,
    required this.showClusters,
    required this.currentScale,
    required this.mapController,
    this.userLocation,
    required this.isResolvingGps,
    required this.onScaleChanged,
  });

  @override
  State<TxenezaMap> createState() => _TxenezaMapState();
}

class _TxenezaMapState extends State<TxenezaMap> with TickerProviderStateMixin {
  // Animate map controller changes
  void _zoomIntoCluster(LatLng target) {
    const double targetZoom = 15.0;
    
    final double startZoom = widget.mapController.camera.zoom;
    final LatLng startCenter = widget.mapController.camera.center;

    final latTween = Tween<double>(begin: startCenter.latitude, end: target.latitude);
    final lngTween = Tween<double>(begin: startCenter.longitude, end: target.longitude);
    final zoomTween = Tween<double>(begin: startZoom, end: targetZoom);

    final animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOutCubic,
    );

    animationController.addListener(() {
      widget.mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animationController.forward().then((_) => animationController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    // Mapbox URL template strings
    // Normal style: mapbox/light-v11 (beautiful desaturated grey-beige tiles)
    // Satellite style: mapbox/satellite-streets-v12 (realistic satellite imagery with street labels)
    // Heatmap style: mapbox/dark-v11 (dark slate theme to make gradients glow)
    final String tileUrl = switch (widget.mapMode) {
      MapMode.normal => 'https://api.mapbox.com/styles/v1/mapbox/light-v11/tiles/256/{z}/{x}/{y}@2x?access_token=${AppEnv.mapboxAccessToken}',
      MapMode.satellite => 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=${AppEnv.mapboxAccessToken}',
      MapMode.heatmap => 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/{z}/{x}/{y}@2x?access_token=${AppEnv.mapboxAccessToken}',
    };

    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: const LatLng(-19.833, 34.850), // Centered on Port of Beira
        initialZoom: 12.5,
        minZoom: 10.0,
        maxZoom: 18.0,
        onPositionChanged: (position, hasGesture) {
          if (position.zoom != widget.currentScale) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onScaleChanged(position.zoom);
            });
          }
        },
      ),
      children: [
        // Layer 1: Tile Images from Mapbox
        TileLayer(
          urlTemplate: tileUrl,
          userAgentPackageName: 'com.txeneza.app',
          retinaMode: true,
        ),

        // Layer 2: Georeferenced Heatmap Circles (Only active in Heatmap mode)
        if (widget.mapMode == MapMode.heatmap)
          CircleLayer(
            circles: [
              // Munhava (Alta densidade)
              CircleMarker(
                point: const LatLng(-19.8100, 34.8150),
                radius: 450,
                useRadiusInMeter: true,
                color: const Color(0xFFFF3B30).withValues(alpha: 0.55),
                borderStrokeWidth: 0,
              ),
              // Ponta Gêa / Centro (Média densidade)
              CircleMarker(
                point: const LatLng(-19.8350, 34.8410),
                radius: 350,
                useRadiusInMeter: true,
                color: const Color(0xFFFF9500).withValues(alpha: 0.50),
                borderStrokeWidth: 0,
              ),
              // Macuti (Baixa densidade)
              CircleMarker(
                point: const LatLng(-19.8250, 34.8700),
                radius: 280,
                useRadiusInMeter: true,
                color: const Color(0xFFFFCC00).withValues(alpha: 0.45),
                borderStrokeWidth: 0,
              ),
            ],
          ),

        // Layer 3: Markers & Clusters (Only active in non-heatmap modes)
        if (widget.mapMode != MapMode.heatmap) ...[
          // Occurrence Markers
          MarkerLayer(
            markers: _buildMarkers(),
          ),

          // User GPS position pulsing dot (If location is active and resolved)
          if (widget.userLocation != null && !widget.isResolvingGps)
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.userLocation ?? const LatLng(0, 0),
                  width: 48,
                  height: 48,
                  child: const _UserPulseMarker(),
                ),
              ],
            ),
        ],

        // Subtle Mapbox/OpenStreetMap attribution in bottom right corner
        const SimpleAttributionWidget(
          source: Text(
            '© Mapbox © OpenStreetMap',
            style: TextStyle(
              fontSize: 9,
              fontFamily: 'Geist',
              color: Colors.black26,
            ),
          ),
          alignment: Alignment.bottomLeft, // Align left so it doesn't conflict with FAB
        ),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    if (widget.showClusters) {
      // Clustered representations using real neighborhood coordinates
      final pgGroup = widget.occurrences.where((o) => o.id == '1' || o.id == '2').toList();
      final mhGroup = widget.occurrences.where((o) => o.id == '3' || o.id == '4' || o.id == '5').toList();
      final mcGroup = widget.occurrences.where((o) => o.id == '6' || o.id == '7' || o.id == '8').toList();
      final ceGroup = widget.occurrences.where((o) => o.id == '9' || o.id == '10').toList();

      final List<Marker> clusterMarkers = [];

      if (pgGroup.isNotEmpty) {
        clusterMarkers.add(_buildClusterMarker(const LatLng(-19.8365, 34.8395), pgGroup));
      }
      if (mhGroup.isNotEmpty) {
        clusterMarkers.add(_buildClusterMarker(const LatLng(-19.8110, 34.8150), mhGroup));
      }
      if (mcGroup.isNotEmpty) {
        clusterMarkers.add(_buildClusterMarker(const LatLng(-19.8243, 34.8710), mcGroup));
      }
      if (ceGroup.isNotEmpty) {
        clusterMarkers.add(_buildClusterMarker(const LatLng(-19.8190, 34.8475), ceGroup));
      }

      return clusterMarkers;
    } else {
      // Individual occurrences
      return widget.occurrences.map((occ) {
        return Marker(
          point: occ.position,
          width: 40,
          height: 50,
          // topCenter faz a ponta inferior do pin apontar a coordenada exata.
          alignment: Alignment.topCenter,
          child: OccurrenceMarkerWidget(
            occurrence: occ,
            currentScale: widget.currentScale,
          ),
        );
      }).toList();
    }
  }

  Marker _buildClusterMarker(LatLng coords, List<Occurrence> items) {
    // Cluster status inherits the highest priority item status
    OccurrenceStatus clusterStatus = OccurrenceStatus.resolved;
    if (items.any((o) => o.status == OccurrenceStatus.critical)) {
      clusterStatus = OccurrenceStatus.critical;
    } else if (items.any((o) => o.status == OccurrenceStatus.pending)) {
      clusterStatus = OccurrenceStatus.pending;
    }

    return Marker(
      point: coords,
      width: 52,
      height: 52,
      child: OccurrenceMarkerWidget(
        clusterCount: items.length,
        clusterStatus: clusterStatus,
        currentScale: widget.currentScale,
        onTap: () {
          _zoomIntoCluster(coords);
        },
      ),
    );
  }
}

// User location pulsating blue dot
class _UserPulseMarker extends StatefulWidget {
  const _UserPulseMarker();

  @override
  State<_UserPulseMarker> createState() => _UserPulseMarkerState();
}

class _UserPulseMarkerState extends State<_UserPulseMarker> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse shadow
              Container(
                width: 24 * _pulseAnimation.value,
                height: 24 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: 1.0 - (_pulseAnimation.value - 1.0) / 1.2),
                ),
              ),
              // Accuracy circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              // Inner core dot
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
