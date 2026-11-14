import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';

import '../theme/app_dialog_tokens.dart';
import '../theme/app_glass_theme.dart';
import '../theme/app_icons.dart';
import '../theme/app_motion.dart';
import '../theme/app_relief_theme.dart';
import '../theme/app_spacing.dart';
import 'app_icon.dart';

/// The shared action surface used by dialogs and sheets.
///
/// Continuous corners and static lighting match the surrounding modal surface.
enum AppActionButtonVariant { primary, secondary, destructive }

class AppActionButton extends HookWidget {
  const AppActionButton({
    required this.label,
    required this.onPressed,
    this.variant = AppActionButtonVariant.secondary,
    this.icon,
    this.busy = false,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppActionButtonVariant variant;
  final AppIconData? icon;
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final states = useMemoized(WidgetStatesController.new);
    useEffect(() => states.dispose, [states]);
    final scale = _usePressScale(context, states, !busy && onPressed != null);
    final glass = context.glass;
    final textTheme = Theme.of(context).textTheme;
    final foreground = switch (variant) {
      AppActionButtonVariant.primary => glass.onAccent,
      AppActionButtonVariant.secondary => glass.foreground,
      AppActionButtonVariant.destructive => glass.dialogDestructive,
    };
    final background = switch (variant) {
      AppActionButtonVariant.primary => glass.accent,
      AppActionButtonVariant.secondary => glass.dialogActionFill,
      AppActionButtonVariant.destructive => glass.dialogDestructiveFill,
    };
    final button = TextButton(
      statesController: states,
      onPressed: busy ? null : onPressed,
      style:
          _actionStyle(
            context,
            foreground,
            background,
            primary: variant == AppActionButtonVariant.primary,
          ).copyWith(
            minimumSize: const WidgetStatePropertyAll(
              Size(0, AppSizes.minTouchTarget),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            textStyle: WidgetStatePropertyAll(
              textTheme.labelLarge?.copyWith(
                fontWeight: variant == AppActionButtonVariant.primary
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
          ),
      child: _ActionButtonContent(
        label: label,
        icon: icon,
        busy: busy,
        expand: expand,
        foreground: foreground,
      ),
    );
    return ScaleTransition(
      scale: scale,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

class _ActionButtonContent extends StatelessWidget {
  const _ActionButtonContent({
    required this.label,
    required this.icon,
    required this.busy,
    required this.expand,
    required this.foreground,
  });

  final String label;
  final AppIconData? icon;
  final bool busy;
  final bool expand;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (busy)
        ConstrainedBox(
          constraints: const BoxConstraints.tightFor(
            width: AppSizes.iconMd,
            height: AppSizes.iconMd,
          ),
          child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
        )
      else if (icon case final icon?)
        AppIcon(icon, size: AppSizes.iconMd),
      if (busy || icon != null) const Gap(AppSpacing.xs),
      Flexible(
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

/// A compact action for icon-only controls inside app-owned dialogs and sheets.
class AppActionIconButton extends HookWidget {
  const AppActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.variant = AppActionButtonVariant.secondary,
    super.key,
  });

  final String tooltip;
  final AppIconData icon;
  final VoidCallback? onPressed;
  final AppActionButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final states = useMemoized(WidgetStatesController.new);
    useEffect(() => states.dispose, [states]);
    final scale = _usePressScale(context, states, onPressed != null);
    final glass = context.glass;
    final foreground = switch (variant) {
      AppActionButtonVariant.primary => glass.onAccent,
      AppActionButtonVariant.secondary => glass.foreground,
      AppActionButtonVariant.destructive => glass.dialogDestructive,
    };
    final background = switch (variant) {
      AppActionButtonVariant.primary => glass.accent,
      AppActionButtonVariant.secondary => glass.dialogActionFill,
      AppActionButtonVariant.destructive => glass.dialogDestructiveFill,
    };
    return ScaleTransition(
      scale: scale,
      child: IconButton(
        statesController: states,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: AppIcon(icon, size: AppSizes.iconMd),
        constraints: const BoxConstraints.tightFor(
          width: AppSizes.minTouchTarget,
          height: AppSizes.minTouchTarget,
        ),
        style:
            _actionStyle(
              context,
              foreground,
              background,
              primary: variant == AppActionButtonVariant.primary,
            ).copyWith(
              minimumSize: const WidgetStatePropertyAll(
                Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
              ),
              maximumSize: const WidgetStatePropertyAll(
                Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
              ),
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            ),
      ),
    );
  }
}

ButtonStyle _actionStyle(
  BuildContext context,
  Color foreground,
  Color background, {
  required bool primary,
}) {
  final relief = AppReliefTheme.of(context);
  return ButtonStyle(
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    shape: WidgetStatePropertyAll(AppDialogTokens.actionShape),
    animationDuration: AppMotion.duration(context, AppMotion.press),
    elevation: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.disabled) ||
              states.contains(WidgetState.pressed)
          ? 0
          : AppReliefTheme.actionElevation,
    ),
    shadowColor: WidgetStatePropertyAll(relief.shadow),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? background.withValues(
              alpha: background.a * AppReliefTheme.disabledAlpha,
            )
          : background,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? foreground.withValues(alpha: AppReliefTheme.disabledAlpha)
          : foreground,
    ),
    side: WidgetStatePropertyAll(relief.border),
    backgroundBuilder: (context, states, child) => DecoratedBox(
      decoration: relief.actionDecoration(
        AppDialogTokens.actionShape,
        states.contains(WidgetState.disabled)
            ? background.withValues(
                alpha: background.a * AppReliefTheme.disabledAlpha,
              )
            : background,
        primary: primary,
        disabled: states.contains(WidgetState.disabled),
        pressed: states.contains(WidgetState.pressed),
      ),
      child: child,
    ),
  );
}

Animation<double> _usePressScale(
  BuildContext context,
  WidgetStatesController states,
  bool enabled,
) {
  final controller = useAnimationController(duration: AppMotion.press);
  final reducedMotion = MediaQuery.disableAnimationsOf(context);
  useEffect(() {
    controller.stop();
    controller.value = 0;
    if (!enabled || reducedMotion) return null;
    // ButtonStyleButton can update disabled/pressed while building. Drive a
    // ticker instead of rebuilding an ancestor in that notification stack.
    void update() => controller.animateTo(
      states.value.contains(WidgetState.pressed) ? 1 : 0,
      curve: AppMotion.pressCurve,
    );
    states.addListener(update);
    return () => states.removeListener(update);
  }, [states, controller, enabled, reducedMotion]);
  return enabled && !reducedMotion
      ? Tween(begin: 1.0, end: AppMotion.pressScale).animate(controller)
      : const AlwaysStoppedAnimation(1);
}
