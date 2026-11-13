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
    required this.messageMetadata,
    required this.accent,
    required this.onAccent,
    required this.bubbleMine,
    required this.onBubbleMine,
    required this.bubbleOther,
    required this.onBubbleOther,
    required this.dialogActionFill,
    required this.dialogDestructiveFill,
    required this.dialogDestructive,
    required this.composerGlowColors,
    required this.composerAiTint,
    required this.composerAiOutline,
  });

  static const AppGlassTheme dark = AppGlassTheme(
    canvasGradient: [Color(0xFF0B0F1A), Color(0xFF1A1340), Color(0xFF0E2A3A)],
    surfaceTint: Color(0x1FFFFFFF),
    surfaceBlur: 16,
    chromeTint: Color(0xAA111827),
    chromeBlur: 28,
    highlightBorder: Color(0x66FFFFFF),
    shadowBorder: Color(0x14FFFFFF),
    foreground: Color(0xFFF5F7FF),
    foregroundMuted: Color(0xB3F5F7FF),
    messageMetadata: Color(0x66F5F7FF),
    accent: Color(0xFF7C9CFF),
    onAccent: Color(0xFF0B0F1A),
    bubbleMine: Color(0xFF006FE6),
    onBubbleMine: Color(0xFFFFFFFF),
    bubbleOther: Color(0xFF252B3C),
    onBubbleOther: Color(0xFFF5F7FF),
    dialogActionFill: Color(0x18FFFFFF),
    dialogDestructiveFill: Color(0x1FFF8A80),
    dialogDestructive: Color(0xFFFF8A80),
    composerGlowColors: [
      Color(0xBFE8B0A8),
      Color(0x99B8D5D0),
      Color(0xB3B4C9E8),
      Color(0x99CDB8E0),
    ],
    composerAiTint: Color(0x99111827),
    composerAiOutline: Color(0x00FFFFFF),
  );

  static const AppGlassTheme light = AppGlassTheme(
    canvasGradient: [Color(0xFFD9E6F6), Color(0xFFEEF2F8), Color(0xFFF7EDE4)],
    surfaceTint: Color(0x99FFFFFF),
    surfaceBlur: 16,
    chromeTint: Color(0xB3FFFFFF),
    chromeBlur: 28,
    highlightBorder: Color(0xCCFFFFFF),
    shadowBorder: Color(0x1A0B0F1A),
    foreground: Color(0xFF0B0F1A),
    foregroundMuted: Color(0xA60B0F1A),
    messageMetadata: Color(0x660B0F1A),
    accent: Color(0xFF3D5AFE),
    onAccent: Color(0xFFFFFFFF),
    bubbleMine: Color(0xFF006FE6),
    onBubbleMine: Color(0xFFFFFFFF),
    bubbleOther: Colors.white,
    onBubbleOther: Color(0xFF0B0F1A),
    dialogActionFill: Color(0x120B0F1A),
    dialogDestructiveFill: Color(0x12B42318),
    dialogDestructive: Color(0xFFB42318),
    composerGlowColors: [
      Color(0xBFF4B4AA),
      Color(0x99C1DDD8),
      Color(0xB3BED0F1),
      Color(0x99D7C2EC),
    ],
    composerAiTint: Color(0x66FFFFFF),
    composerAiOutline: Color(0xE6FFFFFF),
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
  final Color messageMetadata;
  final Color accent;
  final Color onAccent;

  /// Notes the user sends to themself (right-aligned).
  final Color bubbleMine;
  final Color onBubbleMine;

  /// AI replies (left-aligned).
  final Color bubbleOther;
  final Color onBubbleOther;
  final Color dialogActionFill;
  final Color dialogDestructiveFill;
  final Color dialogDestructive;
  final List<Color> composerGlowColors;
  final Color composerAiTint;
  final Color composerAiOutline;

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
    Color? messageMetadata,
    Color? accent,
    Color? onAccent,
    Color? bubbleMine,
    Color? onBubbleMine,
    Color? bubbleOther,
    Color? onBubbleOther,
    Color? dialogActionFill,
    Color? dialogDestructiveFill,
    Color? dialogDestructive,
    List<Color>? composerGlowColors,
    Color? composerAiTint,
    Color? composerAiOutline,
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
      messageMetadata: messageMetadata ?? this.messageMetadata,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      bubbleMine: bubbleMine ?? this.bubbleMine,
      onBubbleMine: onBubbleMine ?? this.onBubbleMine,
      bubbleOther: bubbleOther ?? this.bubbleOther,
      onBubbleOther: onBubbleOther ?? this.onBubbleOther,
      dialogActionFill: dialogActionFill ?? this.dialogActionFill,
      dialogDestructiveFill:
          dialogDestructiveFill ?? this.dialogDestructiveFill,
      dialogDestructive: dialogDestructive ?? this.dialogDestructive,
      composerGlowColors: composerGlowColors == null
          ? this.composerGlowColors
          : List.unmodifiable(composerGlowColors),
      composerAiTint: composerAiTint ?? this.composerAiTint,
      composerAiOutline: composerAiOutline ?? this.composerAiOutline,
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
      messageMetadata: c(messageMetadata, other.messageMetadata),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      bubbleMine: c(bubbleMine, other.bubbleMine),
      onBubbleMine: c(onBubbleMine, other.onBubbleMine),
      bubbleOther: c(bubbleOther, other.bubbleOther),
      onBubbleOther: c(onBubbleOther, other.onBubbleOther),
      dialogActionFill: c(dialogActionFill, other.dialogActionFill),
      dialogDestructiveFill: c(
        dialogDestructiveFill,
        other.dialogDestructiveFill,
      ),
      dialogDestructive: c(dialogDestructive, other.dialogDestructive),
      composerGlowColors: List.unmodifiable([
        for (var i = 0; i < composerGlowColors.length; i++)
          c(composerGlowColors[i], other.composerGlowColors[i]),
      ]),
      composerAiTint: c(composerAiTint, other.composerAiTint),
      composerAiOutline: c(composerAiOutline, other.composerAiOutline),
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
