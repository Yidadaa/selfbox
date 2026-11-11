import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app_glass_theme.dart';

abstract final class AppTheme {
  static ThemeData dark() => _build(AppGlassTheme.dark, Brightness.dark);

  static ThemeData light() => _build(AppGlassTheme.light, Brightness.light);

  static ThemeData _build(AppGlassTheme glass, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: glass.accent,
      brightness: brightness,
    ).copyWith(primary: glass.accent, onSurface: glass.foreground);
    final base = ThemeData(brightness: brightness, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: glass.canvasGradient.first,
      // Glass controls give feedback through press-scale + sheen, not ink.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textTheme: base.textTheme.apply(
        bodyColor: glass.foreground,
        displayColor: glass.foreground,
      ),
      iconTheme: base.iconTheme.copyWith(color: glass.foreground),
      // A single transition for every platform keeps Android and iOS identical
      // and gives both the edge-swipe back gesture with glass page clipping.
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const GlassPageTransitionsBuilder(),
        },
      ),
      extensions: [glass],
    );
  }
}
