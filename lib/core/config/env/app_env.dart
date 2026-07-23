import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static String get mapboxAccessToken => dotenv.get('MAPBOX_ACCESS_TOKEN', fallback: '');

  static String get apiBaseUrl =>
      dotenv.get('API_BASE_URL', fallback: 'https://api.txeneza.example.com');

  static bool get debugMode =>
      dotenv.get('DEBUG_MODE', fallback: 'true').toLowerCase() == 'true';

  // ⚠️ SEGURANÇA: esta chave fica embutida no .env, que é empacotado como
  // asset dentro do APK/IPA compilado — qualquer pessoa que descompacte a
  // app (trivial, ex: abrir o .apk como zip) consegue lê-la em texto
  // simples. Diferente do token do Mapbox ou da chave anónima do Supabase,
  // que são desenhados para serem públicos (protegidos por restrição de
  // domínio/bundle ou por RLS), a API key do Gemini está ligada à
  // facturação/quota da conta Google — se ficar exposta sem restrição,
  // outra pessoa pode usá-la à conta da Txeneza.
  //
  // Mitigação obrigatória (ver README.md secção "Segurança"): restringir
  // esta chave no Google Cloud Console (Credentials -> a chave ->
  // Application restrictions -> Android apps, com o package name
  // com.example.txeneza_app e o SHA-1 de assinatura da app). Isto não
  // pode ser feito por código — é uma configuração na conta Google Cloud.
  static String get geminiApiKey =>
      dotenv.get('GEMINI_API_KEY', fallback: '');

  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');

  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');

  static String get mapboxStyleNormal =>
      dotenv.get('MAPBOX_STYLE_NORMAL', fallback: 'mapbox://styles/tivanepaulo2/cmrovy6jx005q01qt1jb91owi');

  static String get mapboxStyleSatellite =>
      dotenv.get('MAPBOX_STYLE_SATELLITE', fallback: 'mapbox://styles/mapbox/satellite-streets-v12');
}
