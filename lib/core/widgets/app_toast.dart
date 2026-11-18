import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../theme/app_effects.dart';
import '../theme/app_glass_theme.dart';
import '../theme/app_icons.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import 'app_icon.dart';

abstract final class AppToast {
  static VoidCallback show(
    BuildContext context, {
    required String message,
    GlassToastType type = GlassToastType.success,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final themes = InheritedTheme.capture(from: context, to: overlay.context);
    final quality = AppEffects.qualityOf(context, GlassQuality.premium);
    OverlayEntry? entry;
    void dismiss() {
      entry?.remove();
      entry?.dispose();
      entry = null;
    }

    final toastEntry = OverlayEntry(
      builder: (_) => themes.wrap(
        _ToastOverlay(
          message: message,
          type: type,
          quality: quality,
          onDismiss: dismiss,
        ),
      ),
    );
    entry = toastEntry;
    overlay.insert(toastEntry);
    return dismiss;
  }
}

class _ToastOverlay extends HookWidget {
  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.quality,
    required this.onDismiss,
  });

  final String message;
  final GlassToastType type;
  final GlassQuality quality;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.duration(context, AppMotion.medium);
    final controller = useAnimationController(
      duration: duration,
      reverseDuration: duration,
    );
    useEffect(() {
      unawaited(controller.forward());
      final timer = Timer(AppMotion.toastDisplay, () {
        unawaited(controller.reverse().then((_) => onDismiss()));
      });
      return timer.cancel;
    }, [controller]);
    final animation = useMemoized(
      () => CurvedAnimation(parent: controller, curve: AppMotion.emphasized),
      [controller],
    );
    useEffect(() => animation.dispose, [animation]);
    return Positioned(
      bottom:
          math.max(
            MediaQuery.paddingOf(context).bottom,
            MediaQuery.viewInsetsOf(context).bottom,
          ) +
          AppSpacing.huge,
      left: AppInsets.pageHorizontal,
      right: AppInsets.pageHorizontal,
      child: Align(
        alignment: Alignment.topCenter,
        child: FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: AppMotion.pressScale,
              end: 1,
            ).animate(animation),
            child: Dismissible(
              key: ValueKey(message),
              direction: DismissDirection.down,
              resizeDuration: null,
              onDismissed: (_) => onDismiss(),
              child: GlassToast(
                message: message,
                quality: quality,
                type: GlassToastType.neutral,
                onDismissed: onDismiss,
                icon: AppIcon(switch (type) {
                  GlassToastType.success => AppIcons.success,
                  GlassToastType.error => AppIcons.error,
                  GlassToastType.warning => AppIcons.warning,
                  GlassToastType.info ||
                  GlassToastType.neutral => AppIcons.info,
                }, color: context.glass.foregroundMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
