import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/env/app_env.dart';

/// Converte coordenadas no nome do bairro/zona, via API de geocodificação da
/// Mapbox (o mesmo token já usado nos tiles do mapa).
///
/// Feito por HTTP de propósito: o pacote nativo `geocoding` arrasta uma versão
/// antiga do Android Gradle Plugin que conflitua com a do projeto.
class ReverseGeocoder {
  ReverseGeocoder._();

  /// Nome da zona mais específica encontrada, ou null se falhar/não existir.
  /// Nunca lança: o bairro é informação acessória.
  static Future<String?> bairro(double latitude, double longitude) async {
    final token = AppEnv.mapboxAccessToken;
    if (token.isEmpty) return null;

    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$longitude,$latitude.json'
      '?access_token=$token&types=neighborhood,locality,place&limit=1&language=pt',
    );

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final features = json['features'] as List?;
      if (features == null || features.isEmpty) return null;

      final text = (features.first as Map<String, dynamic>)['text'] as String?;
      return (text != null && text.trim().isNotEmpty) ? text.trim() : null;
    } catch (_) {
      return null;
    }
  }
}
