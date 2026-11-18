import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'app_glass_theme.dart';

/// Above the Navigator so routes, sheets and transient overlays share policy.
class AppEffects extends StatelessWidget {
  const AppEffects({
    required this.quality,
    required this.animationsEnabled,
    required this.child,
    super.key,
  });

  final GlassQuality quality;
  final bool animationsEnabled;
  final Widget child;

  /// The requested quality is a budget: only floating chrome requests premium.
  static GlassQuality qualityOf(BuildContext context, GlassQuality fallback) {
    final selected =
        GlassAdaptiveScopeData.maybeOf(context)?.effectiveQuality ?? fallback;
    return switch (selected) {
      GlassQuality.minimal => GlassQuality.minimal,
      GlassQuality.standard =>
        fallback == GlassQuality.minimal
            ? GlassQuality.minimal
            : GlassQuality.standard,
      GlassQuality.premium => fallback,
    };
  }

  static bool isMinimal(BuildContext context) =>
      qualityOf(context, GlassQuality.standard) == GlassQuality.minimal;

  static BorderSide solidBorderOf(BuildContext context) =>
      isMinimal(context) ? context.glass.solidSurfaceBorder : BorderSide.none;

  static Color solidSurface(BuildContext context) {
    final glass = context.glass;
    return Color.alphaBlend(glass.chromeTint, glass.canvasGradient.first);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduceMotion = !animationsEnabled || media.disableAnimations;
    final theme = GlassThemeData.of(context);
    final contentQuality = quality == GlassQuality.minimal
        ? GlassQuality.minimal
        : GlassQuality.standard;
    final skeleton =
        SkeletonizerConfig.maybeOf(context) ?? const SkeletonizerConfigData();
    return MediaQuery(
      data: media.copyWith(disableAnimations: reduceMotion),
      child: GlassAccessibilityScope(
        reduceMotion: reduceMotion,
        child: GlassTheme(
          data: theme.copyWith(
            light: theme.light.copyWith(quality: contentQuality),
            dark: theme.dark.copyWith(quality: contentQuality),
            interaction: reduceMotion
                ? const GlassInteractionSettings(
                    stretch: 0,
                    interactionScale: 1,
                  )
                : theme.interaction,
          ),
          child: GlassAdaptiveScope(
            minQuality: quality,
            maxQuality: quality,
            initialQuality: quality,
            allowStepUp: false,
            child: SkeletonizerConfig(
              data: reduceMotion
                  ? skeleton.copyWith(
                      effectResolver: (_) => SolidColorEffect(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                      enableSwitchAnimation: false,
                    )
                  : skeleton,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
