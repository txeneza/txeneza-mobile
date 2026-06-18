import 'package:flutter/material.dart';
import 'app_colors.dart';

class DarkColors {
  DarkColors._();

  static const Color primary = AppColors.sageGreen;
  static const Color onPrimary = AppColors.forestGreen;
  
  static const Color secondary = AppColors.forestGreen;
  static const Color onSecondary = AppColors.white;

  static const Color accent = AppColors.limeGreen;
  static const Color onAccent = AppColors.grey900;

  static const Color background = AppColors.grey900;
  static const Color onBackground = AppColors.grey50;

  static const Color surface = Color(0xFF1E2F2C); // Dark variant of forest/sage green
  static const Color onSurface = AppColors.grey50;

  static const Color error = AppColors.error;
  static const Color onError = AppColors.white;
}
