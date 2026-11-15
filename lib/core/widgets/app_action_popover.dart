import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../theme/app_motion.dart';
import '../theme/app_popover_tokens.dart';
import '../theme/app_spacing.dart';
import 'app_popover_surface.dart';

export 'app_popover_region.dart';
export 'app_popover_surface.dart' show AppPopoverAction;

class AppActionPopover extends HookWidget {
  const AppActionPopover({
    required this.anchor,
    required this.actions,
    this.radius = AppPopoverTokens.radius,
    this.itemKeys,
    this.highlightedIndex,
    super.key,
  });
  final Offset anchor;
  final List<AppPopoverAction> actions;
  final double radius;
  final List<GlobalKey>? itemKeys;
  final int? highlightedIndex;

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final animation = useAnimationController(duration: AppMotion.fast);
    final hovered = useState<int?>(null);
    final fingerDown = useRef(false);
    final keys = useMemoized(
      () => List<GlobalKey>.generate(actions.length, (_) => GlobalKey()),
      [actions.length],
    );
    final actionKeys = itemKeys ?? keys;
    useEffect(() {
      reduceMotion ? animation.value = 1 : animation.forward();
      return null;
    }, [reduceMotion]);
    final surface = Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        fingerDown.value = true;
        hovered.value = popoverActionAt(actionKeys, event.position);
      },
      onPointerMove: (event) {
        if (fingerDown.value) {
          hovered.value = popoverActionAt(actionKeys, event.position);
        }
      },
      onPointerUp: (event) {
        if (!fingerDown.value) return;
        fingerDown.value = false;
        final index = popoverActionAt(actionKeys, event.position);
        hovered.value = null;
        if (index != null) actions[index].onPressed();
      },
      onPointerCancel: (_) {
        fingerDown.value = false;
        hovered.value = null;
      },
      child: AppPopoverSurface(
        actions: actions,
        radius: radius,
        itemKeys: actionKeys,
        highlightedIndex: highlightedIndex ?? hovered.value,
      ),
    );
    return CustomSingleChildLayout(
      delegate: _PopoverLayout(
        anchor,
        EdgeInsets.fromLTRB(
          safe.left + AppSpacing.md,
          safe.top + AppSpacing.md,
          safe.right + AppSpacing.md,
          math.max(safe.bottom, keyboard.bottom) + AppSpacing.md,
        ),
      ),
      child: reduceMotion
          ? surface
          : surface
                .animate(controller: animation, autoPlay: false)
                .fadeIn(duration: AppMotion.duration(context, AppMotion.fast))
                .scaleXY(
                  begin: AppMotion.pressScale,
                  duration: AppMotion.duration(context, AppMotion.fast),
                  curve: AppMotion.emphasized,
                ),
    );
  }
}

class _PopoverLayout extends SingleChildLayoutDelegate {
  const _PopoverLayout(this.anchor, this.insets);
  final Offset anchor;
  final EdgeInsets insets;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: math.max(0, constraints.maxWidth - insets.horizontal),
        maxHeight: math.max(0, constraints.maxHeight - insets.vertical),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final above = anchor.dy - AppSpacing.xs - childSize.height;
    final top = above >= insets.top ? above : anchor.dy + AppSpacing.xs;
    return Offset(
      (anchor.dx - childSize.width / 2).clamp(
        insets.left,
        math.max(insets.left, size.width - insets.right - childSize.width),
      ),
      top.clamp(
        insets.top,
        math.max(insets.top, size.height - insets.bottom - childSize.height),
      ),
    );
  }

  @override
  bool shouldRelayout(_PopoverLayout oldDelegate) =>
      anchor != oldDelegate.anchor || insets != oldDelegate.insets;
}
