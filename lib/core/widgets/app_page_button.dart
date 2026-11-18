import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
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
    this.iconSize = AppSizes.iconMd,
    this.trailingIconGap = AppSpacing.xs,
    this.trailingIcon = false,
    this.height,
    this.busy = false,
    this.destructive = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final AppIconData? icon;
  final double iconSize;
  final double trailingIconGap;
  final bool trailingIcon;
  final double? height;
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
      height: height,
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
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: height == null ? AppSpacing.sm : 0,
          ),
          child: Skeletonizer(
            enabled: busy,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if ((trailingIcon, icon) case (false, final icon?)) ...[
                  AppIcon(icon, size: iconSize, color: color),
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
                if ((trailingIcon, icon) case (true, final icon?)) ...[
                  Gap(trailingIconGap),
                  AppIcon(icon, size: iconSize, color: color),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
