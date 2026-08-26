import 'package:flutter/material.dart';

/// Colors ported 1:1 from the web app's `oklch()` design tokens in styles.css.
class AppColors {
  AppColors._();

  // Light theme (the app only ships light mode, matching the web default).
  static const background = Color(0xFFF8F5F0);
  static const foreground = Color(0xFF2D2824);
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFFEEEBE2);
  static const mutedForeground = Color(0xFF69625A);
  static const border = Color(0x142D2824); // foreground @ 8%
  static const ring = Color(0xFF708774);

  // MoodFit brand tokens
  static const sage = Color(0xFF788D78);
  static Color get sageSoft => sage.withValues(alpha: 0.12);
  static const blueMist = Color(0xFF6D8AA3);
  static const beige = Color(0xFFE5DDD0);
  static const amberWarm = Color(0xFFE69B4C);
  static const amberDeep = Color(0xFF793900);

  static Color paletteToColor(String palette) {
    switch (palette) {
      case 'blue-mist':
        return blueMist;
      case 'beige':
        return beige;
      case 'amber-warm':
        return amberWarm;
      default:
        return sage;
    }
  }
}
