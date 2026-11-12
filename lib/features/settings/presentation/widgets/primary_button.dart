import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Full-width glass action button; ignores taps while [busy].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    return GlassButton.custom(
      quality: GlassQuality.premium,
      height: AppSizes.minTouchTarget,
      width: double.infinity,
      label: label,
      enabled: !busy,
      shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.pill),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy)
            const SizedBox.square(
              dimension: AppSizes.iconMd,
              child: GlassProgressIndicator.circular(),
            )
          else if (icon != null)
            Icon(icon, size: AppSizes.iconMd),
          if (busy || icon != null) const Gap(AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
