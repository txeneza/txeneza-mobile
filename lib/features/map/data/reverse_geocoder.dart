import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/env/app_env.dart';
import '../../../core/constants/beira_neighborhoods.dart';

/// Converte coordenadas no nome do bairro/zona oficial da Beira.
///
/// Utiliza resolução espacial local baseada na malha canónica dos 31 bairros da Beira
/// com enriquecimento opcional via API de geocodificação da Mapbox quando online.
class ReverseGeocoder {
  ReverseGeocoder._();

  /// Nome do bairro oficial da Beira identificado para o par (latitude, longitude).
  /// Nunca falha ou lança exceção: em modo offline ou falha de rede recorre
  /// imediatamente ao cálculo euclidiano local sobre os 31 bairros oficiais.
  static Future<String> bairro(double latitude, double longitude) async {
    // 1. Cálculo canónico local garantido (offline e 0ms)
    final localBairro = BeiraNeighborhoods.findClosestBairro(latitude, longitude);

    final token = AppEnv.mapboxAccessToken;
    if (token.isEmpty) return localBairro;

    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$longitude,$latitude.json'
      '?access_token=$token&types=neighborhood,locality,place&limit=1&language=pt',
    );

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return localBairro;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final features = json['features'] as List?;
      if (features == null || features.isEmpty) return localBairro;

      final text = (features.first as Map<String, dynamic>)['text'] as String?;
      if (text != null && text.trim().isNotEmpty) {
        final trim = text.trim();
        // Se a Mapbox devolveu um nome que casa com um bairro oficial da Beira, adota-o
        final matched = BeiraNeighborhoods.list.firstWhere(
          (b) => b.toLowerCase() == trim.toLowerCase(),
          orElse: () => '',
        );
        if (matched.isNotEmpty) {
          return matched;
        }
      }

      return localBairro;
    } catch (_) {
      return localBairro;
    }
  }
}
