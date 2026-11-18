import 'package:selfbox/core/theme/sdk_material.dart';

import 'app_glass_theme.dart';

/// Static lighting for opaque modal surfaces; no backdrop or shader passes.
@immutable
class AppReliefTheme extends ThemeExtension<AppReliefTheme> {
  const AppReliefTheme({
    required this.top,
    required this.middle,
    required this.bottom,
    required this.outline,
    required this.highlight,
    required this.shade,
    required this.shadow,
  });

  factory AppReliefTheme.fromGlass(AppGlassTheme glass, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return AppReliefTheme(
      top: Color.alphaBlend(
        Colors.white.withValues(alpha: dark ? 0.055 : 0),
        glass.bubbleOther,
      ),
      middle: glass.bubbleOther,
      bottom: Color.alphaBlend(
        glass.foreground.withValues(alpha: dark ? 0 : 0.035),
        glass.bubbleOther,
      ),
      outline: glass.foreground.withValues(alpha: dark ? 0.12 : 0.09),
      highlight: Colors.white.withValues(alpha: dark ? 0.025 : 0.40),
      shade: Colors.black.withValues(alpha: dark ? 0.10 : 0.035),
      shadow: Colors.black.withValues(alpha: dark ? 0.30 : 0.10),
    );
  }

  static const double disabledAlpha = 0.45;
  static const double actionElevation = 1.5;

  final Color top;
  final Color middle;
  final Color bottom;
  final Color outline;
  final Color highlight;
  final Color shade;
  final Color shadow;

  static AppReliefTheme of(BuildContext context) =>
      Theme.of(context).extension<AppReliefTheme>() ??
      AppReliefTheme.fromGlass(context.glass, Theme.of(context).brightness);

  BorderSide get border => BorderSide(color: outline, width: 0.75);

  LinearGradient get surfaceGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [top, middle, bottom],
    stops: const [0, 0.45, 1],
  );

  List<BoxShadow> get surfaceShadows => [
    BoxShadow(color: shadow, blurRadius: 32, offset: const Offset(0, 12)),
    BoxShadow(
      color: shadow.withValues(alpha: shadow.a * 0.45),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  ShapeDecoration actionDecoration(
    OutlinedBorder shape,
    Color fill, {
    required bool disabled,
    required bool pressed,
    bool primary = false,
  }) {
    final base = Color.alphaBlend(fill, middle);
    final strength = disabled ? 0.35 : 1.0;
    final upper = Color.alphaBlend(
      highlight.withValues(
        alpha:
            (primary ? highlight.a.clamp(0.0, 0.06) : highlight.a) * strength,
      ),
      base,
    );
    final lower = Color.alphaBlend(
      shade.withValues(alpha: shade.a * strength),
      base,
    );
    return ShapeDecoration(
      shape: shape.copyWith(
        side: border.copyWith(
          color: outline.withValues(alpha: outline.a * strength),
        ),
      ),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: pressed ? [lower, base] : [upper, base, lower],
      ),
    );
  }

  @override
  AppReliefTheme copyWith({
    Color? top,
    Color? middle,
    Color? bottom,
    Color? outline,
    Color? highlight,
    Color? shade,
    Color? shadow,
  }) => AppReliefTheme(
    top: top ?? this.top,
    middle: middle ?? this.middle,
    bottom: bottom ?? this.bottom,
    outline: outline ?? this.outline,
    highlight: highlight ?? this.highlight,
    shade: shade ?? this.shade,
    shadow: shadow ?? this.shadow,
  );

  @override
  AppReliefTheme lerp(covariant AppReliefTheme? other, double t) {
    if (other == null) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return AppReliefTheme(
      top: blend(top, other.top),
      middle: blend(middle, other.middle),
      bottom: blend(bottom, other.bottom),
      outline: blend(outline, other.outline),
      highlight: blend(highlight, other.highlight),
      shade: blend(shade, other.shade),
      shadow: blend(shadow, other.shadow),
    );
  }
}
