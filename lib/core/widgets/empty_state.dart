import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_glass_theme.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Empty / error placeholder: an icon, one short label and an optional action
/// placed outside the card (glass controls never nest in glass cards).
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.label,
    this.action,
    super.key,
  });

  final IconData icon;
  final String label;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final action = this.action;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassContainer.card(
            padding: const EdgeInsets.all(AppSpacing.xl),
            shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: AppSizes.iconHero,
                  color: glass.foregroundMuted,
                ),
                const Gap(AppSpacing.sm),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: glass.foregroundMuted),
                ),
              ],
            ),
          ),
          if (action != null) ...[const Gap(AppSpacing.lg), action],
        ],
      ),
    );
  }
}
