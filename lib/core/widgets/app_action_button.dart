import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/app_glass_theme.dart';
import '../theme/app_spacing.dart';

/// The shared action surface used by dialogs, sheets, and settings forms.
///
/// Every variant keeps the same touch target and rounded geometry. A tonal fill
/// carries the interaction cue so secondary and destructive actions stay quiet
/// inside an opaque dialog surface.
enum AppActionButtonVariant { primary, secondary, destructive }

class AppActionButton extends StatelessWidget {
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
  final IconData? icon;
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) {
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
      onPressed: busy ? null : onPressed,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(0, AppSizes.minTouchTarget),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? background.withValues(alpha: background.a * 0.45)
              : background,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? foreground.withValues(alpha: 0.45)
              : foreground,
        ),
        side: const WidgetStatePropertyAll(BorderSide.none),
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
    return expand ? SizedBox(width: double.infinity, child: button) : button;
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
  final IconData? icon;
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
      else if (icon != null)
        Icon(icon, size: AppSizes.iconMd),
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
class AppActionIconButton extends StatelessWidget {
  const AppActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.variant = AppActionButtonVariant.secondary,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final AppActionButtonVariant variant;

  @override
  Widget build(BuildContext context) {
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
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: AppSizes.iconMd),
      constraints: const BoxConstraints.tightFor(
        width: AppSizes.minTouchTarget,
        height: AppSizes.minTouchTarget,
      ),
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
        ),
        maximumSize: const WidgetStatePropertyAll(
          Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? background.withValues(alpha: background.a * 0.45)
              : background,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? foreground.withValues(alpha: 0.45)
              : foreground,
        ),
        side: const WidgetStatePropertyAll(BorderSide.none),
      ),
    );
  }
}
