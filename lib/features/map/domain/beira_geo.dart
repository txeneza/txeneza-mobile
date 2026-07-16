import 'package:latlong2/latlong.dart';

/// Validação geográfica: garante que uma denúncia foi feita dentro da cidade
/// da Beira, evitando registos fora da área de estudo.
///
/// A verificação é feita em duas etapas, ambas no dispositivo (offline):
///   1. bounding box — rejeição rápida e barata de pontos claramente fora;
///   2. point-in-polygon (ray-casting) — refina para a forma real da cidade.
class BeiraGeo {
  BeiraGeo._();

  // Bounding box aproximado da cidade da Beira (canto SO e NE).
  static const double _minLat = -19.90;
  static const double _maxLat = -19.74;
  static const double _minLng = 34.79;
  static const double _maxLng = 34.92;

  /// Centro aproximado da Beira, usado como fallback quando não há GPS.
  static const LatLng center = LatLng(-19.833, 34.850);

  /// Polígono APROXIMADO da fronteira da cidade da Beira, no sentido horário.
  ///
  /// NÃO é a fronteira administrativa oficial — é um contorno grosseiro traçado
  /// a partir da extensão conhecida da cidade, suficiente para filtrar denúncias
  /// fora da área. Substituir pelos vértices do GeoJSON oficial quando disponível
  /// (o algoritmo [_pointInPolygon] funciona com qualquer polígono).
  static const List<LatLng> polygon = [
    LatLng(-19.745, 34.840), // norte (Munhava/Inhamízua)
    LatLng(-19.760, 34.885),
    LatLng(-19.790, 34.905),
    LatLng(-19.825, 34.910), // leste (orla, Macúti)
    LatLng(-19.855, 34.900),
    LatLng(-19.885, 34.870), // sul (foz, Praia Nova)
    LatLng(-19.890, 34.835),
    LatLng(-19.870, 34.805),
    LatLng(-19.830, 34.795), // oeste (Chota/Manga)
    LatLng(-19.790, 34.800),
    LatLng(-19.760, 34.815),
  ];

  static bool isInsideBoundingBox(LatLng p) {
    return p.latitude >= _minLat &&
        p.latitude <= _maxLat &&
        p.longitude >= _minLng &&
        p.longitude <= _maxLng;
  }

  /// True se o ponto estiver dentro da Beira (bounding box e depois polígono).
  static bool isInsideBeira(LatLng p) {
    if (!isInsideBoundingBox(p)) return false;
    return _pointInPolygon(p, polygon);
  }

  /// Algoritmo ray-casting: conta cruzamentos de uma semirreta horizontal com
  /// as arestas do polígono. Ímpar = dentro, par = fora.
  static bool _pointInPolygon(LatLng p, List<LatLng> poly) {
    bool inside = false;
    final double x = p.longitude;
    final double y = p.latitude;

    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final double xi = poly[i].longitude, yi = poly[i].latitude;
      final double xj = poly[j].longitude, yj = poly[j].latitude;

      final bool intersects = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (intersects) inside = !inside;
    }
    return inside;
  }
}
