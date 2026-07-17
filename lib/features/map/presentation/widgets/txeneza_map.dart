import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/env/app_env.dart';
import '../../../../core/theme/colors/app_colors.dart';
import '../../domain/occurrence_model.dart';
import '../../domain/ponto_recolha_model.dart';
import 'occurrence_marker_widget.dart';
import 'ponto_recolha_marker.dart';

enum MapMode { normal, satellite, heatmap }

class TxenezaMap extends StatefulWidget {
  final MapMode mapMode;
  final List<Occurrence> occurrences;
  final List<PontoRecolha> pontosRecolha;
  final bool showClusters;
  final double currentScale; // Used as current zoom level
  final void Function(MapboxMap) onMapCreated;
  final latlong.LatLng? userLocation;
  final bool isResolvingGps;
  final ValueChanged<double> onScaleChanged;

  const TxenezaMap({
    super.key,
    required this.mapMode,
    required this.occurrences,
    this.pontosRecolha = const [],
    required this.showClusters,
    required this.currentScale,
    required this.onMapCreated,
    this.userLocation,
    required this.isResolvingGps,
    required this.onScaleChanged,
  });

  @override
  State<TxenezaMap> createState() => _TxenezaMapState();
}

class _TxenezaMapState extends State<TxenezaMap> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  CircleAnnotationManager? _circleAnnotationManager;
  final Map<String, dynamic> _annotationPayloads = {};

  @override
  void didUpdateWidget(covariant TxenezaMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.occurrences != oldWidget.occurrences ||
        widget.pontosRecolha != oldWidget.pontosRecolha ||
        widget.showClusters != oldWidget.showClusters ||
        widget.mapMode != oldWidget.mapMode ||
        widget.currentScale != oldWidget.currentScale) {
      
      if (widget.mapMode != oldWidget.mapMode) {
        _updateStyle();
      }
      _renderMarkersAndCircles();
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    widget.onMapCreated(mapboxMap);

    // Definir posição da câmara inicial (Beira) apenas uma vez
    await mapboxMap.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(34.850, -19.833)), // Longitude, Latitude
        zoom: 12.5,
      ),
    );

    // Ativar o ponto azul de localização nativo do Mapbox
    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        showAccuracyRing: true,
      ),
    );

    // Inicializar os Annotation Managers
    _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    _circleAnnotationManager = await mapboxMap.annotations.createCircleAnnotationManager();

    // Registar eventos de cliques via stream
    _pointAnnotationManager?.tapEvents(
      onTap: (annotation) {
        final payload = _annotationPayloads[annotation.id];
        if (payload is Occurrence) {
          _handleOccurrenceTap(payload);
        } else if (payload is PontoRecolha) {
          showPontoRecolhaDetails(context, payload);
        } else if (payload is latlong.LatLng) {
          _zoomIntoCluster(payload);
        }
      },
    );

    _renderMarkersAndCircles();
  }

  void _updateStyle() {
    if (_mapboxMap == null) return;
    final styleUri = switch (widget.mapMode) {
      MapMode.normal => AppEnv.mapboxStyleNormal,
      MapMode.satellite => AppEnv.mapboxStyleSatellite,
      MapMode.heatmap => AppEnv.mapboxStyleHeatmap,
    };
    _mapboxMap!.loadStyleURI(styleUri);
  }

  void _zoomIntoCluster(latlong.LatLng target) async {
    if (_mapboxMap == null) return;
    await _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(target.longitude, target.latitude)),
        zoom: 15.0,
      ),
      MapAnimationOptions(duration: 700),
    );
  }

  void _handleOccurrenceTap(Occurrence occ) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${occ.title}: ${occ.description}',
          style: const TextStyle(fontFamily: 'Geist'),
        ),
        backgroundColor: const Color(0xFF01403A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  double _getPixelRadius(double metersRadius, latlong.LatLng point, double zoom) {
    final latitudeInRad = point.latitude * math.pi / 180.0;
    final metersPerPixel = 156543.03 * math.cos(latitudeInRad) / math.pow(2, zoom);
    return metersRadius / metersPerPixel;
  }

  void _createHeatmapCircle(latlong.LatLng center, double metersRadius, Color color) async {
    if (_circleAnnotationManager == null) return;
    final radiusInPixels = _getPixelRadius(metersRadius, center, widget.currentScale);

    final options = CircleAnnotationOptions(
      geometry: Point(coordinates: Position(center.longitude, center.latitude)),
      circleColor: color.toARGB32(),
      circleRadius: radiusInPixels,
      circleOpacity: 0.55,
      circleStrokeWidth: 0.0,
    );
    await _circleAnnotationManager!.create(options);
  }

  Future<void> _createClusterMarker(latlong.LatLng coords, List<Occurrence> items) async {
    if (_pointAnnotationManager == null) return;

    OccurrenceStatus clusterStatus = OccurrenceStatus.resolved;
    if (items.any((o) => o.status == OccurrenceStatus.critical)) {
      clusterStatus = OccurrenceStatus.critical;
    } else if (items.any((o) => o.status == OccurrenceStatus.pending)) {
      clusterStatus = OccurrenceStatus.pending;
    }

    final color = occurrenceStatusColor(clusterStatus);
    final clusterImage = await _generateClusterMarker(count: items.length, color: color);

    final options = PointAnnotationOptions(
      geometry: Point(coordinates: Position(coords.longitude, coords.latitude)),
      image: clusterImage,
      iconSize: 0.5,
    );
    final annotation = await _pointAnnotationManager!.create(options);
    _annotationPayloads[annotation.id] = coords;
  }

  Future<void> _renderMarkersAndCircles() async {
    if (_mapboxMap == null || _pointAnnotationManager == null || _circleAnnotationManager == null) return;

    // Limpar os marcadores anteriores
    await _pointAnnotationManager!.deleteAll();
    await _circleAnnotationManager!.deleteAll();
    _annotationPayloads.clear();

    if (widget.mapMode == MapMode.heatmap) {
      if (widget.occurrences.isNotEmpty) {
        for (final occ in widget.occurrences) {
          final color = occurrenceStatusColor(occ.status);
          _createHeatmapCircle(occ.position, 150.0, color);
        }
      } else {
        // Fallback para mockups se a base de dados estiver vazia
        _createHeatmapCircle(const latlong.LatLng(-19.8100, 34.8150), 450, const Color(0xFFFF3B30));
        _createHeatmapCircle(const latlong.LatLng(-19.8350, 34.8410), 350, const Color(0xFFFF9500));
        _createHeatmapCircle(const latlong.LatLng(-19.8250, 34.8700), 280, const Color(0xFFFFCC00));
      }
    } else {
      // Pontos de recolha oficiais
      if (widget.pontosRecolha.isNotEmpty) {
        final pontoRecolhaImage = await _generatePontoRecolhaMarker();
        for (final ponto in widget.pontosRecolha) {
          final options = PointAnnotationOptions(
            geometry: Point(coordinates: Position(ponto.position.longitude, ponto.position.latitude)),
            image: pontoRecolhaImage,
            iconSize: 0.58,
          );
          final annotation = await _pointAnnotationManager!.create(options);
          _annotationPayloads[annotation.id] = ponto;
        }
      }

      // Ocorrências
      if (widget.showClusters) {
        final pgGroup = widget.occurrences.where((o) => o.id == '1' || o.id == '2').toList();
        final mhGroup = widget.occurrences.where((o) => o.id == '3' || o.id == '4' || o.id == '5').toList();
        final mcGroup = widget.occurrences.where((o) => o.id == '6' || o.id == '7' || o.id == '8').toList();
        final ceGroup = widget.occurrences.where((o) => o.id == '9' || o.id == '10').toList();

        if (pgGroup.isNotEmpty) await _createClusterMarker(const latlong.LatLng(-19.8365, 34.8395), pgGroup);
        if (mhGroup.isNotEmpty) await _createClusterMarker(const latlong.LatLng(-19.8110, 34.8150), mhGroup);
        if (mcGroup.isNotEmpty) await _createClusterMarker(const latlong.LatLng(-19.8243, 34.8710), mcGroup);
        if (ceGroup.isNotEmpty) await _createClusterMarker(const latlong.LatLng(-19.8190, 34.8475), ceGroup);
      } else {
        for (final occ in widget.occurrences) {
          final color = occurrenceStatusColor(occ.status);
          final icon = occurrenceStatusIcon(occ.status);
          final pinImage = await _generateTeardropPin(color: color, icon: icon);

          final options = PointAnnotationOptions(
            geometry: Point(coordinates: Position(occ.position.longitude, occ.position.latitude)),
            image: pinImage,
            iconSize: 0.5,
            iconAnchor: IconAnchor.BOTTOM,
          );
          final annotation = await _pointAnnotationManager!.create(options);
          _annotationPayloads[annotation.id] = occ;
        }
      }
    }
  }

  // --- Desenho em Canvas na Memória (Uint8List PNG) ---

  Future<Uint8List> _generateTeardropPin({
    required Color color,
    required IconData icon,
    double width = 80.0,
    double height = 100.0,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const double stroke = 4.0;
    final double r = width / 2 - stroke;
    final Offset head = Offset(width / 2, r + stroke);

    final headPath = Path()..addOval(Rect.fromCircle(center: head, radius: r));
    final tailPath = Path()
      ..moveTo(head.dx - r * 0.66, head.dy + r * 0.5)
      ..lineTo(head.dx + r * 0.66, head.dy + r * 0.5)
      ..lineTo(width / 2, height)
      ..close();
    final pin = Path.combine(PathOperation.union, headPath, tailPath);

    canvas.drawShadow(pin, Colors.black.withValues(alpha: 0.35), 8.0, false);
    canvas.drawPath(pin, Paint()..color = color);
    canvas.drawPath(
      pin,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    canvas.drawCircle(
      head,
      r - 6,
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 32,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(head.dx - textPainter.width / 2, head.dy - textPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _generateClusterMarker({
    required int count,
    required Color color,
    double width = 104.0,
    double height = 104.0,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final double center = width / 2;

    canvas.drawCircle(
      Offset(center, center),
      center,
      Paint()..color = color.withValues(alpha: 0.18),
    );

    canvas.drawCircle(
      Offset(center, center),
      40.0,
      Paint()..color = color,
    );

    canvas.drawCircle(
      Offset(center, center),
      40.0,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: '$count',
      style: const TextStyle(
        fontFamily: 'Geist',
        color: Colors.white,
        fontSize: 30,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center - textPainter.width / 2, center - textPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _generatePontoRecolhaMarker({
    double width = 150.0,
    double height = 150.0,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final double center = width / 2;
    final double radius = (width / 2) - 10;

    // Brilho exterior (sombra de neon em tons de verde)
    final glowPaint = Paint()
      ..color = AppColors.limeGreen.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center, center), radius + 8, glowPaint);

    final outerRingPaint = Paint()
      ..color = AppColors.forestGreen
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center, center), radius + 2, outerRingPaint);

    // Círculo branco de fundo
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center, center), radius - 2, bgPaint);

    try {
      // Carrega o logótipo oficial TXENEZA
      final data = await DefaultAssetBundle.of(context).load('assets/images/TXENEZA.png');
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: (radius * 1.5).toInt(),
        targetHeight: (radius * 1.5).toInt(),
      );
      final frame = await codec.getNextFrame();
      final ui.Image logoImage = frame.image;

      final double logoSize = radius * 1.5;
      final double logoOffset = center - (logoSize / 2);

      // Recorta a imagem para o interior do círculo
      canvas.save();
      final clipPath = Path()..addOval(Rect.fromCircle(center: Offset(center, center), radius: radius - 3));
      canvas.clipPath(clipPath);

      canvas.drawImage(logoImage, Offset(logoOffset, logoOffset), Paint());
      canvas.restore();
    } catch (e) {
      // Fallback elegante se falhar
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(
        text: String.fromCharCode(LucideIcons.trash2.codePoint),
        style: TextStyle(
          fontSize: 48,
          fontFamily: LucideIcons.trash2.fontFamily,
          package: LucideIcons.trash2.fontPackage,
          color: AppColors.forestGreen,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center - textPainter.width / 2, center - textPainter.height / 2),
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final styleUri = switch (widget.mapMode) {
      MapMode.normal => AppEnv.mapboxStyleNormal,
      MapMode.satellite => AppEnv.mapboxStyleSatellite,
      MapMode.heatmap => AppEnv.mapboxStyleHeatmap,
    };

    return MapWidget(
      key: const ValueKey('mapbox_widget'),
      styleUri: styleUri,
      onMapCreated: _onMapCreated,
      onCameraChangeListener: (data) {
        final zoom = data.cameraState.zoom;
        if (zoom != widget.currentScale) {
          widget.onScaleChanged(zoom);
        }
      },
    );
  }
}
