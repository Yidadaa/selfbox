import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/app_effects.dart';
import '../theme/app_glass_theme.dart';
import '../theme/app_icons.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_icon.dart';

class AppPageButton extends StatelessWidget {
  const AppPageButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.destructive = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final AppIconData? icon;
  final bool busy;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final enabled = !busy && onPressed != null;
    final color = destructive
        ? context.glass.dialogDestructive
        : context.glass.foreground;
    return GlassButton.custom(
      quality: AppEffects.qualityOf(context, GlassQuality.standard),
      shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.pill),
      width: double.infinity,
      enabled: enabled,
      label: label,
      onTap: () {
        if (!enabled) return;
        HapticFeedback.lightImpact();
        onPressed?.call();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Skeletonizer(
            enabled: busy,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon case final icon?) ...[
                  AppIcon(icon, color: color),
                  const Gap(AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
