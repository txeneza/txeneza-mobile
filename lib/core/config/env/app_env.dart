import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static String get mapboxAccessToken => dotenv.get('MAPBOX_ACCESS_TOKEN', fallback: '');

  static String get apiBaseUrl =>
      dotenv.get('API_BASE_URL', fallback: 'https://api.txeneza.example.com');

  static bool get debugMode =>
      dotenv.get('DEBUG_MODE', fallback: 'true').toLowerCase() == 'true';

  static String get geminiApiKey =>
      dotenv.get('GEMINI_API_KEY', fallback: '');

  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');

  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');

  static String get mapboxStyleNormal =>
      dotenv.get('MAPBOX_STYLE_NORMAL', fallback: 'mapbox://styles/tivanepaulo2/cmrovy6jx005q01qt1jb91owi');

  static String get mapboxStyleSatellite =>
      dotenv.get('MAPBOX_STYLE_SATELLITE', fallback: 'mapbox://styles/mapbox/satellite-streets-v12');

  static String get mapboxStyleHeatmap =>
      dotenv.get('MAPBOX_STYLE_HEATMAP', fallback: 'mapbox://styles/mapbox/dark-v11');
}
