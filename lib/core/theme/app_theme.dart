import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// The exact CSS `cubic-bezier(0.16, 1, 0.3, 1)` used for `.animate-fade-in`.
const Curve kFadeInCurve = Cubic(0.16, 1.0, 0.3, 1.0);
const Duration kFadeInDuration = Duration(milliseconds: 800);

class AppTheme {
  AppTheme._();

  static TextStyle mono({
    double fontSize = 10,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double letterSpacing = 0.5,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.foreground.withValues(alpha: 0.6),
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle sans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.foreground,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static ThemeData get theme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        surface: AppColors.background,
        primary: AppColors.foreground,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.foreground,
        displayColor: AppColors.foreground,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
