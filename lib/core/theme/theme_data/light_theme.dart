import 'package:flutter/material.dart';
import '../colors/light_colors.dart';
import '../typography/text_styles.dart';
import '../spacing/app_radius.dart';

ThemeData get lightTheme {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: LightColors.primary,
      onPrimary: LightColors.onPrimary,
      secondary: LightColors.secondary,
      onSecondary: LightColors.onSecondary,
      tertiary: LightColors.accent,
      onTertiary: LightColors.onAccent,
      surface: LightColors.surface,
      onSurface: LightColors.onSurface,
      error: LightColors.error,
      onError: LightColors.onError,
    ),
    scaffoldBackgroundColor: LightColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: LightColors.primary,
      foregroundColor: LightColors.onPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyles.titleLarge,
      headlineMedium: TextStyles.titleMedium,
      titleLarge: TextStyles.subtitleLarge,
      titleMedium: TextStyles.subtitleMedium,
      bodyLarge: TextStyles.body,
      bodyMedium: TextStyles.body,
      labelLarge: TextStyles.captionLarge,
      labelSmall: TextStyles.captionSmall,
    ),
    cardTheme: CardThemeData(
      color: LightColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderMD,
        side: BorderSide(
          color: LightColors.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LightColors.surface.withValues(alpha: 0.1),
      border: const OutlineInputBorder(
        borderRadius: AppRadius.borderMD,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderMD,
        borderSide: BorderSide(
          color: LightColors.secondary.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadius.borderMD,
        borderSide: BorderSide(
          color: LightColors.primary,
          width: 2,
        ),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppRadius.borderMD,
        borderSide: BorderSide(
          color: LightColors.error,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LightColors.primary,
        foregroundColor: LightColors.onPrimary,
        minimumSize: const Size(88, 48), // Ensure minimum 48px touch target height
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderMD,
        ),
        textStyle: TextStyles.bodyBold,
      ),
    ),
  );
}
