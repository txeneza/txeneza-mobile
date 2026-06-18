import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> low = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> high = [
    BoxShadow(
      color: Color(0x26000000),
      offset: Offset(0, 8),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];
}
