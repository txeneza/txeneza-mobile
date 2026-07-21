import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/config/env/app_env.dart';
import 'features/notification/services/local_notification_service.dart';
import 'features/notification/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }

  // Firebase.initializeApp() detecta a configuração a partir do
  // android/app/google-services.json (Android) e do GoogleService-Info.plist
  // (iOS) automaticamente. Se preferir gerar lib/firebase_options.dart com o
  // FlutterFire CLI (`flutterfire configure`), troque para
  // `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
  await Firebase.initializeApp();

  // Regista o handler de mensagens em segundo plano o mais cedo possível.
  FCMService.registerBackgroundHandler();

  MapboxOptions.setAccessToken(AppEnv.mapboxAccessToken);

  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    // A chave fornecida é uma publishable key (sb_publishable_...).
    publishableKey: AppEnv.supabaseAnonKey,
  );

  await themeProvider.init();

  // Apenas configura o plugin (canais, etc). O pedido de permissão em runtime
  // é feito na tela de permissões (onboarding), junto com Câmara e Localização.
  await LocalNotificationService.initialize();
  await FCMService.initialize();

  runApp(const App());
}

