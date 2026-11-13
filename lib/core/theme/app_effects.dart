import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

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

  static GlassQuality qualityOf(BuildContext context, GlassQuality fallback) =>
      GlassAdaptiveScopeData.maybeOf(context)?.effectiveQuality ?? fallback;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduceMotion = !animationsEnabled || media.disableAnimations;
    final theme = GlassThemeData.of(context);
    final skeleton =
        SkeletonizerConfig.maybeOf(context) ?? const SkeletonizerConfigData();
    return MediaQuery(
      data: media.copyWith(disableAnimations: reduceMotion),
      child: GlassAccessibilityScope(
        reduceMotion: reduceMotion,
        child: GlassTheme(
          data: theme.copyWith(
            light: theme.light.copyWith(quality: quality),
            dark: theme.dark.copyWith(quality: quality),
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
