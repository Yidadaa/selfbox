import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/app_glass_theme.dart';
import '../theme/app_spacing.dart';

/// A quiet placeholder; failures may add an action below the label.
class EmptyState extends StatelessWidget {
  const EmptyState({required this.label, this.action, this.color, super.key});

  final String label;
  final Widget? action;
  final Color? color;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: color ?? context.glass.foregroundMuted),
          ),
          if (action case final button?) ...[const Gap(AppSpacing.lg), button],
        ],
      ),
    ),
  );
}
