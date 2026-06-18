import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double circular = 999.0;

  // BorderRadius objects
  static const BorderRadius borderXS = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSM = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMD = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLG = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXL = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderCircular = BorderRadius.all(Radius.circular(circular));
}
