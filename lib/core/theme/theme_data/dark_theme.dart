import 'package:flutter/material.dart';
import '../colors/dark_colors.dart';
import '../typography/text_styles.dart';
import '../spacing/app_radius.dart';

ThemeData get darkTheme {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: DarkColors.primary,
      onPrimary: DarkColors.onPrimary,
      secondary: DarkColors.secondary,
      onSecondary: DarkColors.onSecondary,
      tertiary: DarkColors.accent,
      onTertiary: DarkColors.onAccent,
      surface: DarkColors.surface,
      onSurface: DarkColors.onSurface,
      error: DarkColors.error,
      onError: DarkColors.onError,
    ),
    scaffoldBackgroundColor: DarkColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: DarkColors.secondary,
      foregroundColor: DarkColors.onSecondary,
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
      color: DarkColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderMD,
        side: BorderSide(
          color: DarkColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DarkColors.surface,
      border: const OutlineInputBorder(
        borderRadius: AppRadius.borderMD,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderMD,
        borderSide: BorderSide(
          color: DarkColors.primary.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadius.borderMD,
        borderSide: BorderSide(
          color: DarkColors.primary,
          width: 2,
        ),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppRadius.borderMD,
        borderSide: BorderSide(
          color: DarkColors.error,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DarkColors.primary,
        foregroundColor: DarkColors.onPrimary,
        minimumSize: const Size(88, 48), // Ensure minimum 48px touch target height
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderMD,
        ),
        textStyle: TextStyles.bodyBold,
      ),
    ),
  );
}
