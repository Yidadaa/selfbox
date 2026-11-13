import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';

import '../theme/app_icons.dart';
import '../theme/app_motion.dart';
import '../theme/app_popover_tokens.dart';
import '../theme/app_spacing.dart';
import '../theme/message_tokens.dart';
import 'app_icon.dart';
import 'pressable.dart';

@immutable
class AppPopoverAction {
  const AppPopoverAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });
  final String label;
  final AppIconData icon;
  final VoidCallback onPressed;
  final bool destructive;
}

class AppPopoverRegion extends HookWidget {
  const AppPopoverRegion({
    required this.actions,
    required this.builder,
    this.radius = MessageTokens.radius,
    super.key,
  });
  final List<AppPopoverAction> actions;
  final Widget Function(BuildContext, ValueChanged<Offset>) builder;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final anchor = useState<Offset?>(null);
    final portal = useMemoized(OverlayPortalController.new);
    useEffect(() {
      if (anchor.value == null && !portal.isShowing) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        anchor.value == null ? portal.hide() : portal.show();
      });
      return null;
    }, [anchor.value]);
    return PopScope(
      canPop: anchor.value == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) anchor.value = null;
      },
      child: OverlayPortal(
        overlayLocation: OverlayChildLocation.rootOverlay,
        controller: portal,
        overlayChildBuilder: (_) => Stack(
          children: [
            ModalBarrier(
              onDismiss: () => anchor.value = null,
              semanticsLabel: MaterialLocalizations.of(context)
                  .modalBarrierDismissLabel,
            ),
            if (anchor.value case final point?)
              AppActionPopover(
                anchor: point,
                radius: radius,
                actions: [
                  for (final action in actions)
                    AppPopoverAction(
                      label: action.label,
                      icon: action.icon,
                      destructive: action.destructive,
                      onPressed: () {
                        anchor.value = null;
                        action.onPressed();
                      },
                    ),
                ],
              ),
          ],
        ),
        child: builder(context, (point) => anchor.value = point),
      ),
    );
  }
}

class AppActionPopover extends HookWidget {
  const AppActionPopover({
    required this.anchor,
    required this.actions,
    this.radius = MessageTokens.radius,
    super.key,
  });
  final Offset anchor;
  final List<AppPopoverAction> actions;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final animation = useAnimationController(duration: AppMotion.fast);
    useEffect(() {
      reduceMotion ? animation.value = 1 : animation.forward();
      return null;
    }, [reduceMotion]);
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
      child: _PopoverSurface(actions: actions, radius: radius)
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

class _PopoverSurface extends StatelessWidget {
  const _PopoverSurface({required this.actions, required this.radius});
  final List<AppPopoverAction> actions;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('app-popover-surface'),
    decoration: BoxDecoration(
      color: AppPopoverTokens.background,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [AppPopoverTokens.shadow],
    ),
    child: SizedBox(
      width: AppPopoverTokens.width,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final action in actions) _PopoverItem(action: action),
          ],
        ),
      ),
    ),
  );
}

class _PopoverItem extends StatelessWidget {
  const _PopoverItem({required this.action});
  final AppPopoverAction action;

  @override
  Widget build(BuildContext context) {
    final color = action.destructive
        ? AppPopoverTokens.destructive
        : AppPopoverTokens.foreground;
    return Pressable(
      semanticLabel: action.label,
      onTap: action.onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            AppIcon(action.icon, color: color),
            const Gap(AppSpacing.sm),
            Expanded(
              child: Text(
                action.label,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: color),
              ),
            ),
          ],
        ),
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
