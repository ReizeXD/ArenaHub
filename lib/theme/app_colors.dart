import 'package:flutter/material.dart';

/// Paleta do design "Athletic Modernist", exportado do Stitch.
///
/// Os valores vêm dos tokens do Tailwind no HTML exportado — que é o que as
/// telas realmente renderizam. A seção em prosa do DESIGN.md cita outra
/// paleta (#059669); ela não corresponde ao desenho.
abstract final class AppColors {
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceDim = Color(0xFFCBDBF5);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceHigh = Color(0xFFDCE9FF);
  static const Color surfaceHighest = Color(0xFFD3E4FE);

  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF3D4A42);

  static const Color outline = Color(0xFF6D7A72);
  static const Color outlineVariant = Color(0xFFBCCAC0);

  static const Color primary = Color(0xFF006948);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF00855D);
  static const Color onPrimaryContainer = Color(0xFFF5FFF7);
  static const Color primaryFixed = Color(0xFF85F8C4);
  static const Color inversePrimary = Color(0xFF68DBA9);

  static const Color secondary = Color(0xFF565E74);
  static const Color secondaryContainer = Color(0xFFDAE2FD);
  static const Color onSecondaryContainer = Color(0xFF5C647A);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color inverseSurface = Color(0xFF213145);
  static const Color inverseOnSurface = Color(0xFFEAF1FF);
}
