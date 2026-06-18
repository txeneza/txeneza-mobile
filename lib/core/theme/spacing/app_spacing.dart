import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // Spacing values based on 8px grid
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;   // Screen edge margins
  static const double lg = 24.0;   // Section spacing
  static const double xl = 32.0;   // Generous spacing
  static const double xxl = 48.0;  // Minimum touch target area size / very large spacing
  static const double xxxl = 64.0;

  // Touch Target Constants
  static const double minTouchTarget = 48.0;

  // Vertical Spaces
  static const SizedBox verticalSpaceXXS = SizedBox(height: xxs);
  static const SizedBox verticalSpaceXS = SizedBox(height: xs);
  static const SizedBox verticalSpaceSM = SizedBox(height: sm);
  static const SizedBox verticalSpaceMD = SizedBox(height: md);
  static const SizedBox verticalSpaceLG = SizedBox(height: lg);
  static const SizedBox verticalSpaceXL = SizedBox(height: xl);
  static const SizedBox verticalSpaceXXL = SizedBox(height: xxl);

  // Horizontal Spaces
  static const SizedBox horizontalSpaceXXS = SizedBox(width: xxs);
  static const SizedBox horizontalSpaceXS = SizedBox(width: xs);
  static const SizedBox horizontalSpaceSM = SizedBox(width: sm);
  static const SizedBox horizontalSpaceMD = SizedBox(width: md);
  static const SizedBox horizontalSpaceLG = SizedBox(width: lg);
  static const SizedBox horizontalSpaceXL = SizedBox(width: xl);
  static const SizedBox horizontalSpaceXXL = SizedBox(width: xxl);
}
