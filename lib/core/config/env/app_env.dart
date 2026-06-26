import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static String get mapboxAccessToken => dotenv.get('MAPBOX_ACCESS_TOKEN', fallback: '');

  static String get apiBaseUrl =>
      dotenv.get('API_BASE_URL', fallback: 'https://api.txeneza.example.com');

  static bool get debugMode =>
      dotenv.get('DEBUG_MODE', fallback: 'true').toLowerCase() == 'true';
}
