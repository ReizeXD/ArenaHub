import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Raios de canto do design.
abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;

  static BorderRadius get card => BorderRadius.circular(xl);
  static BorderRadius get slot => BorderRadius.circular(lg);
  static BorderRadius get sheet => BorderRadius.circular(xxl);
}

/// Grade de 8pt do design.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Margem horizontal das telas.
  static const double margin = 16;

  /// Folga no fim das listas para não ficar sob a barra inferior.
  static const double bottomSafeArea = 88;
}

/// Elevação por sombra difusa, como no design.
abstract final class AppShadows {
  /// Cartões e blocos de horário.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A0B1C30),
      blurRadius: 20,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  /// Cartão selecionado ou em destaque, com halo esverdeado.
  static const List<BoxShadow> accent = [
    BoxShadow(
      color: Color(0x1F006948),
      blurRadius: 25,
      offset: Offset(0, 10),
      spreadRadius: -4,
    ),
  ];

  /// Barra inferior fixa — sombra para cima.
  static const List<BoxShadow> bottomBar = [
    BoxShadow(
      color: Color(0x140B1C30),
      blurRadius: 30,
      offset: Offset(0, -8),
    ),
  ];
}

abstract final class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerLowest: AppColors.surfaceLowest,
      surfaceContainerLow: AppColors.surfaceLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceHigh,
      surfaceContainerHighest: AppColors.surfaceHighest,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppText.family,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: const TextTheme(
        displayLarge: AppText.displayLg,
        displayMedium: AppText.displayMobile,
        headlineLarge: AppText.headlineLg,
        headlineMedium: AppText.headlineMd,
        headlineSmall: AppText.headlineSm,
        bodyLarge: AppText.bodyLg,
        bodyMedium: AppText.bodyMd,
        bodySmall: AppText.bodySm,
        labelLarge: AppText.labelLg,
        labelMedium: AppText.labelMd,
        labelSmall: AppText.labelCaps,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(52),
          textStyle: AppText.labelLg,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.slot),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.slot,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.slot,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.slot,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.slot,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.slot,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }
}
