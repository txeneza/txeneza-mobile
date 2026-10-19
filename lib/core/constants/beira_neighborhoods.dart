import 'dart:math' as math;

/// Resultado da resolução espacial de coordenadas na Cidade da Beira.
class BairroResolution {
  final String nome;
  final bool isDentroDaBeira;
  final double distanciaCentroKm;

  const BairroResolution({
    required this.nome,
    required this.isDentroDaBeira,
    required this.distanciaCentroKm,
  });
}

/// Lista canónica dos 31 bairros oficiais da Cidade da Beira, Moçambique.
///
/// Ordenada alfabeticamente. Inclui centróides geográficos para resolução
/// automática de bairro a partir de coordenadas GPS [lat, lng].
class BeiraNeighborhoods {
  BeiraNeighborhoods._();

  /// Limites da caixa delimitadora (Bounding Box) do perímetro municipal da Beira.
  static const double minLat = -20.0000;
  static const double maxLat = -19.6500;
  static const double minLng = 34.7500;
  static const double maxLng = 35.0000;

  /// Limiar de tolerância máxima em quilómetros relativamente ao centróide mais próximo.
  static const double maxToleranceKm = 15.0;

  /// Rótulo atribuído a coordenadas fora do perímetro de cobertura da Beira.
  static const String foraDaBeira = 'Fora da Beira';

  static const List<String> list = [
    'Alto da Manga',
    'Alvalade',
    'Central',
    'Chaimite',
    'Chingussura',
    'Chipangara',
    'Chota',
    'Estoril',
    'Esturro',
    'Goto',
    'Inhamizua',
    'Macurungo',
    'Macuti',
    'Manga',
    'Manga Mascarenha',
    'Maraza',
    'Matacuane',
    'Matadouro',
    'Matope',
    'Muave',
    'Mungassa',
    'Munhava',
    'Ndunda',
    'Nhaconjo',
    'Nhangau',
    'Nhangoma',
    'Pioneiros',
    'Ponta Gêa',
    'Tchondja',
    'Vaz Manga',
    'Vila Massane',
  ];

  /// Centros geográficos aproximados de cada bairro [lat, lng].
  static const Map<String, List<double>> centers = {
    'Alto da Manga': [-19.7950, 34.8800],
    'Alvalade': [-19.8280, 34.8620],
    'Central': [-19.8350, 34.8390],
    'Chaimite': [-19.8342, 34.8362],
    'Chingussura': [-19.7480, 34.8720],
    'Chipangara': [-19.8322, 34.8445],
    'Chota': [-19.8200, 34.8250],
    'Estoril': [-19.8480, 34.8820],
    'Esturro': [-19.8250, 34.8560],
    'Goto': [-19.8312, 34.8442],
    'Inhamizua': [-19.7252, 34.8141],
    'Macurungo': [-19.8372, 34.8803],
    'Macuti': [-19.8435, 34.8928],
    'Manga': [-19.7890, 34.8750],
    'Manga Mascarenha': [-19.7950, 34.8900],
    'Maraza': [-19.8080, 34.8685],
    'Matacuane': [-19.8318, 34.8583],
    'Matadouro': [-19.8120, 34.8420],
    'Matope': [-19.7620, 34.8550],
    'Muave': [-19.7350, 34.8300],
    'Mungassa': [-19.7780, 34.8950],
    'Munhava': [-19.8150, 34.8450],
    'Ndunda': [-19.7520, 34.8380],
    'Nhaconjo': [-19.7688, 34.8690],
    'Nhangau': [-19.7050, 34.9150],
    'Nhangoma': [-19.7400, 34.8900],
    'Pioneiros': [-19.8260, 34.8480],
    'Ponta Gêa': [-19.8446, 34.8472],
    'Tchondja': [-19.7820, 34.8600],
    'Vaz Manga': [-19.7900, 34.8710],
    'Vila Massane': [-19.8180, 34.8590],
  };

  /// Resolve a localização espacial de um par de coordenadas, devolvendo
  /// a informação de integridade geográfica no Município da Beira.
  static BairroResolution resolveBairro(double lat, double lng) {
    if (!lat.isFinite || !lng.isFinite) {
      return const BairroResolution(
        nome: foraDaBeira,
        isDentroDaBeira: false,
        distanciaCentroKm: double.infinity,
      );
    }

    // Verificação rápida de Bounding Box
    final bool foraBoundingBox =
        lat < minLat || lat > maxLat || lng < minLng || lng > maxLng;

    String closestName = 'Central';
    double minDistanceKm = double.infinity;

    centers.forEach((bairro, coords) {
      final double dLatKm = (lat - coords[0]) * 110.574;
      final double dLngKm = (lng - coords[1]) *
          111.320 *
          math.cos(coords[0] * math.pi / 180.0);
      final double distKm = math.sqrt(dLatKm * dLatKm + dLngKm * dLngKm);

      if (distKm < minDistanceKm) {
        minDistanceKm = distKm;
        closestName = bairro;
      }
    });

    final bool isDentro = !foraBoundingBox && (minDistanceKm <= maxToleranceKm);

    return BairroResolution(
      nome: isDentro ? closestName : foraDaBeira,
      isDentroDaBeira: isDentro,
      distanciaCentroKm: minDistanceKm,
    );
  }

  /// Determina o bairro canónico oficial da Beira mais próximo.
  /// Caso a coordenada esteja fora do perímetro municipal (ou a mais de 15 km),
  /// devolve 'Fora da Beira' em vez de forçar a associação errónea.
  static String findClosestBairro(double lat, double lng) {
    return resolveBairro(lat, lng).nome;
  }
}