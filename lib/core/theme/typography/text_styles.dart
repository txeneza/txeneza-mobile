import 'package:flutter/material.dart';
import 'font_families.dart';

class TextStyles {
  TextStyles._();

  // Line Height multiplier (standard: 1.5x)
  static const double _defaultHeight = 1.5;

  // Font weights
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Screen Titles (28 - 32px)
  static const TextStyle titleLarge = TextStyle(
    fontFamily: FontFamilies.primary,
    fontSize: 32.0,
    fontWeight: bold,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: FontFamilies.primary,
    fontSize: 28.0,
    fontWeight: bold,
    height: 1.4,
  );

  // Section Subtitles (22 - 24px)
  static const TextStyle subtitleLarge = TextStyle(
    fontFamily: FontFamilies.primary,
    fontSize: 24.0,
    fontWeight: semiBold,
    height: _defaultHeight,
  );

  static const TextStyle subtitleMedium = TextStyle(
    fontFamily: FontFamilies.primary,
    fontSize: 22.0,
    fontWeight: semiBold,
    height: _defaultHeight,
  );

  // Body text (16px)
  static const TextStyle body = TextStyle(
    fontFamily: FontFamilies.primary,
    fontSize: 16.0,
    fontWeight: regular,
    height: _defaultHeight,
  );

  static const TextStyle bodyBold = TextStyle(
    fontFamily: FontFamilies.primary,
    fontSize: 16.0,
    fontWeight: bold,
    height: _defaultHeight,
  );

  // Caption/Auxiliary texts (12 - 14px)
  static const TextStyle captionLarge = TextStyle(
    fontFamily: FontFamilies.primary,
    fontSize: 14.0,
    fontWeight: regular,
    height: _defaultHeight,
  );

  static const TextStyle captionSmall = TextStyle(
    fontFamily: FontFamilies.primary,
    fontSize: 12.0,
    fontWeight: regular,
    height: _defaultHeight,
  );
}
