import 'package:flutter/material.dart';

import 'nexo_colors.dart';

abstract final class NexoTypography {
  static const String sans = 'Geist';
  static const String mono = 'GeistMono';

  static TextTheme textTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: sans,
        fontSize: 40,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: NexoColors.ink,
      ),
      displayMedium: TextStyle(
        fontFamily: sans,
        fontSize: 32,
        height: 1.18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: NexoColors.ink,
      ),
      headlineLarge: TextStyle(
        fontFamily: sans,
        fontSize: 24,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: NexoColors.ink,
      ),
      headlineMedium: TextStyle(
        fontFamily: sans,
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: NexoColors.ink,
      ),
      titleLarge: TextStyle(
        fontFamily: sans,
        fontSize: 18,
        height: 1.35,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: NexoColors.ink,
      ),
      titleMedium: TextStyle(
        fontFamily: sans,
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: NexoColors.ink,
      ),
      titleSmall: TextStyle(
        fontFamily: sans,
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: NexoColors.ink,
      ),
      bodyLarge: TextStyle(
        fontFamily: sans,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w500,
        color: NexoColors.ink,
      ),
      bodyMedium: TextStyle(
        fontFamily: sans,
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: NexoColors.ink,
      ),
      bodySmall: TextStyle(
        fontFamily: sans,
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: NexoColors.inkLow,
      ),
      labelLarge: TextStyle(
        fontFamily: sans,
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: NexoColors.ink,
      ),
      labelMedium: TextStyle(
        fontFamily: sans,
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: NexoColors.inkLow,
      ),
    );
  }

  static TextStyle monoStyle({
    double size = 14,
    double height = 1.3,
    FontWeight weight = FontWeight.w600,
    Color color = NexoColors.ink,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: mono,
      fontSize: size,
      height: height,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}
