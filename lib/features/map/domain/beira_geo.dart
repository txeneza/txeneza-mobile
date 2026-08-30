import 'package:latlong2/latlong.dart';

/// Validação geográfica: garante que uma denúncia foi feita dentro da cidade
/// da Beira, evitando registos fora da área de estudo.
///
/// A verificação é feita em duas etapas, ambas no dispositivo (offline):
///   1. bounding box — rejeição rápida e barata de pontos claramente fora;
///   2. point-in-polygon (ray-casting) — refina para a forma real da cidade.
class BeiraGeo {
  BeiraGeo._();

  // Bounding box da cidade da Beira cobrindo todos os 31 bairros oficiais.
  static const double _minLat = -19.92;
  static const double _maxLat = -19.68;
  static const double _minLng = 34.76;
  static const double _maxLng = 34.96;

  /// Centro aproximado da Beira, usado como fallback quando não há GPS.
  static const LatLng center = LatLng(-19.833, 34.850);

  /// Polígono abrangente da cidade da Beira (sentido horário).
  static const List<LatLng> polygon = [
    LatLng(-19.680, 34.880), // norte (Nhangau / Nhangoma)
    LatLng(-19.720, 34.930), // nordeste
    LatLng(-19.760, 34.930),
    LatLng(-19.825, 34.920), // leste (Macuti / Estoril)
    LatLng(-19.855, 34.910),
    LatLng(-19.890, 34.880), // sul (Ponta Gêa / Porto)
    LatLng(-19.895, 34.835),
    LatLng(-19.870, 34.800),
    LatLng(-19.820, 34.780), // oeste
    LatLng(-19.740, 34.785), // noroeste (Muave / Chingussura)
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
