import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Optical parameters for the three spatial depth layers
/// (canvas -> surface glass -> floating chrome).
@immutable
class AppGlassTheme extends ThemeExtension<AppGlassTheme> {
  const AppGlassTheme({
    required this.canvasGradient,
    required this.surfaceTint,
    required this.surfaceBlur,
    required this.chromeTint,
    required this.chromeBlur,
    required this.highlightBorder,
    required this.shadowBorder,
    required this.foreground,
    required this.foregroundMuted,
    required this.accent,
  });

  static const AppGlassTheme dark = AppGlassTheme(
    canvasGradient: [Color(0xFF0B0F1A), Color(0xFF1A1340), Color(0xFF0E2A3A)],
    surfaceTint: Color(0x1FFFFFFF),
    surfaceBlur: 16,
    chromeTint: Color(0x33FFFFFF),
    chromeBlur: 28,
    highlightBorder: Color(0x66FFFFFF),
    shadowBorder: Color(0x14FFFFFF),
    foreground: Color(0xFFF5F7FF),
    foregroundMuted: Color(0xB3F5F7FF),
    accent: Color(0xFF7C9CFF),
  );

  static const AppGlassTheme light = AppGlassTheme(
    canvasGradient: [Color(0xFFEAF0FF), Color(0xFFF6E9FF), Color(0xFFE3F6F5)],
    surfaceTint: Color(0x99FFFFFF),
    surfaceBlur: 16,
    chromeTint: Color(0xB3FFFFFF),
    chromeBlur: 28,
    highlightBorder: Color(0xCCFFFFFF),
    shadowBorder: Color(0x1A0B0F1A),
    foreground: Color(0xFF0B0F1A),
    foregroundMuted: Color(0xA60B0F1A),
    accent: Color(0xFF3D5AFE),
  );

  static AppGlassTheme of(Brightness brightness) => switch (brightness) {
    Brightness.dark => dark,
    Brightness.light => light,
  };

  final List<Color> canvasGradient;
  final Color surfaceTint;
  final double surfaceBlur;
  final Color chromeTint;
  final double chromeBlur;

  /// Edge lit by the virtual light source entering from the top-left at 45°.
  final Color highlightBorder;
  final Color shadowBorder;
  final Color foreground;
  final Color foregroundMuted;
  final Color accent;

  @override
  AppGlassTheme copyWith({
    List<Color>? canvasGradient,
    Color? surfaceTint,
    double? surfaceBlur,
    Color? chromeTint,
    double? chromeBlur,
    Color? highlightBorder,
    Color? shadowBorder,
    Color? foreground,
    Color? foregroundMuted,
    Color? accent,
  }) {
    return AppGlassTheme(
      canvasGradient: canvasGradient ?? this.canvasGradient,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      surfaceBlur: surfaceBlur ?? this.surfaceBlur,
      chromeTint: chromeTint ?? this.chromeTint,
      chromeBlur: chromeBlur ?? this.chromeBlur,
      highlightBorder: highlightBorder ?? this.highlightBorder,
      shadowBorder: shadowBorder ?? this.shadowBorder,
      foreground: foreground ?? this.foreground,
      foregroundMuted: foregroundMuted ?? this.foregroundMuted,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppGlassTheme lerp(covariant AppGlassTheme? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t) ?? b;
    double d(double a, double b) => lerpDouble(a, b, t) ?? b;
    return AppGlassTheme(
      canvasGradient: List.unmodifiable([
        for (var i = 0; i < canvasGradient.length; i++)
          c(canvasGradient[i], other.canvasGradient[i]),
      ]),
      surfaceTint: c(surfaceTint, other.surfaceTint),
      surfaceBlur: d(surfaceBlur, other.surfaceBlur),
      chromeTint: c(chromeTint, other.chromeTint),
      chromeBlur: d(chromeBlur, other.chromeBlur),
      highlightBorder: c(highlightBorder, other.highlightBorder),
      shadowBorder: c(shadowBorder, other.shadowBorder),
      foreground: c(foreground, other.foreground),
      foregroundMuted: c(foregroundMuted, other.foregroundMuted),
      accent: c(accent, other.accent),
    );
  }
}

extension AppGlassThemeContext on BuildContext {
  AppGlassTheme get glass {
    final theme = Theme.of(this);
    return theme.extension<AppGlassTheme>() ??
        AppGlassTheme.of(theme.brightness);
  }
}
