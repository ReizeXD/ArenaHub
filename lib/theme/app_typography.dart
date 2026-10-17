import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Escala tipográfica do design, em Plus Jakarta Sans.
///
/// Os valores saem do `fontSize` do Tailwind exportado. O CSS mede
/// entrelinha em pixels e espaçamento em `em`; o Flutter usa `height` como
/// múltiplo do tamanho e `letterSpacing` em pixels — a conversão já está
/// feita abaixo.
abstract final class AppText {
  static const String family = 'PlusJakartaSans';

  static const TextStyle displayLg = TextStyle(
    fontSize: 36,
    height: 44 / 36,
    letterSpacing: -1.08,
    fontWeight: FontWeight.w800,
    color: AppColors.onSurface,
  );

  static const TextStyle displayMobile = TextStyle(
    fontSize: 28,
    height: 36 / 28,
    letterSpacing: -0.7,
    fontWeight: FontWeight.w800,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineLg = TextStyle(
    fontSize: 24,
    height: 32 / 24,
    letterSpacing: -0.48,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineMd = TextStyle(
    fontSize: 20,
    height: 28 / 20,
    letterSpacing: -0.3,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineSm = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: -0.16,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  static const TextStyle labelLg = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: -0.14,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static const TextStyle labelMd = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.24,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceVariant,
  );

  /// Usado apenas em caixa alta: selos de status e etiquetas de modalidade.
  static const TextStyle labelCaps = TextStyle(
    fontSize: 11,
    height: 14 / 11,
    letterSpacing: 0.66,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurfaceVariant,
  );
}
