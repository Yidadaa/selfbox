import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

enum HapticKind { selection, light, heavy, none }

/// Tap target for non-glass controls: guarantees a 48dp hit area, the
/// standard press-scale feedback, and a haptic tick.
class Pressable extends HookWidget {
  const Pressable({
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.haptic = HapticKind.selection,
    this.semanticLabel,
    this.minSize = AppSizes.minTouchTarget,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final HapticKind haptic;
  final String? semanticLabel;
  final double minSize;

  static void _feedback(HapticKind kind) => switch (kind) {
    HapticKind.selection => HapticFeedback.selectionClick(),
    HapticKind.light => HapticFeedback.lightImpact(),
    HapticKind.heavy => HapticFeedback.heavyImpact(),
    HapticKind.none => null,
  };

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final onTap = this.onTap;
    final onLongPress = this.onLongPress;
    final enabled = onTap != null || onLongPress != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => pressed.value = true : null,
        onTapUp: enabled ? (_) => pressed.value = false : null,
        onTapCancel: enabled ? () => pressed.value = false : null,
        onTap: onTap == null
            ? null
            : () {
                _feedback(haptic);
                onTap();
              },
        onLongPress: onLongPress == null
            ? null
            : () {
                pressed.value = false;
                _feedback(HapticKind.light);
                onLongPress();
              },
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
          child: AnimatedScale(
            scale: pressed.value ? AppMotion.pressScale : 1,
            duration: AppMotion.press,
            curve: AppMotion.pressCurve,
            child: Center(widthFactor: 1, heightFactor: 1, child: child),
          ),
        ),
      ),
    );
  }
}
