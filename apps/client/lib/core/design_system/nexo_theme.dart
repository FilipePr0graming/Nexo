import 'package:flutter/material.dart';

import 'nexo_colors.dart';
import 'nexo_radius.dart';
import 'nexo_spacing.dart';
import 'nexo_typography.dart';

abstract final class NexoTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: NexoColors.accent,
      onPrimary: Colors.black,
      secondary: NexoColors.accent,
      onSecondary: Colors.black,
      error: NexoColors.error,
      onError: Colors.white,
      surface: NexoColors.surface,
      onSurface: NexoColors.ink,
    );

    OutlineInputBorder border(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(NexoRadius.md),
        borderSide: BorderSide(color: color, width: 1),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: NexoTypography.sans,
      scaffoldBackgroundColor: NexoColors.canvas,
      colorScheme: colorScheme,
      textTheme: NexoTypography.textTheme(),
      dividerColor: NexoColors.divider,
      iconTheme: const IconThemeData(
        color: NexoColors.ink,
        size: 20,
      ),
      cardTheme: CardThemeData(
        color: NexoColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexoRadius.lg),
          side: const BorderSide(color: NexoColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NexoColors.surfaceElevated,
        hintStyle: const TextStyle(color: NexoColors.inkLow),
        labelStyle: const TextStyle(color: NexoColors.inkMedium),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: NexoSpacing.md,
          vertical: NexoSpacing.md,
        ),
        border: border(NexoColors.border),
        enabledBorder: border(NexoColors.border),
        focusedBorder: border(NexoColors.accent),
        errorBorder: border(NexoColors.error),
        focusedErrorBorder: border(NexoColors.error),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: NexoColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: NexoColors.surfaceElevated,
        contentTextStyle: NexoTypography.textTheme().bodyMedium?.copyWith(
          color: NexoColors.ink,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexoRadius.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          backgroundColor: NexoColors.accent,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: NexoSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NexoRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: NexoTypography.sans,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          foregroundColor: NexoColors.ink,
          side: const BorderSide(color: NexoColors.border),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: NexoSpacing.lg),
          backgroundColor: NexoColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NexoRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: NexoTypography.sans,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NexoColors.inkMedium,
          minimumSize: const Size(0, 44),
          textStyle: const TextStyle(
            fontFamily: NexoTypography.sans,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: NexoColors.surfaceElevated,
        selectedColor: NexoColors.surfaceElevated,
        secondarySelectedColor: NexoColors.surfaceElevated,
        disabledColor: NexoColors.surfaceMuted,
        side: const BorderSide(color: NexoColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexoRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        labelStyle: const TextStyle(
          fontFamily: NexoTypography.sans,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: NexoColors.ink,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: NexoTypography.sans,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: NexoColors.ink,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: const WidgetStatePropertyAll(
            BorderSide(color: NexoColors.border),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? NexoColors.surfaceElevated
                : NexoColors.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? NexoColors.inkHigh
                : NexoColors.ink,
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: NexoTypography.sans,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NexoRadius.pill),
            ),
          ),
        ),
      ),
    );
  }
}
