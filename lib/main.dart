import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/env/app_env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }

  MapboxOptions.setAccessToken(AppEnv.mapboxAccessToken);

  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    // A chave fornecida é uma publishable key (sb_publishable_...).
    publishableKey: AppEnv.supabaseAnonKey,
  );

  runApp(const App());
}

