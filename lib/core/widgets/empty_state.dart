import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/app_artwork_tokens.dart';
import '../theme/app_glass_theme.dart';
import '../theme/app_spacing.dart';
import 'app_artwork.dart';

/// A quiet placeholder; failures may add an action below the label.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.label,
    this.action,
    this.color,
    this.illustration,
    this.illustrationSize = AppArtworkTokens.hero,
    super.key,
  });

  final String label;
  final Widget? action;
  final Color? color;
  final BrandArt? illustration;
  final double illustrationSize;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration case final art?) ...[
              AppArtwork(
                art,
                size: math.min(
                  illustrationSize,
                  constraints.hasBoundedHeight
                      ? constraints.maxHeight * 0.4
                      : illustrationSize,
                ),
              ),
              const Gap(AppSpacing.md),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style:
                  (illustration == null
                          ? Theme.of(context).textTheme.bodySmall
                          : Theme.of(context).textTheme.bodyMedium)
                      ?.copyWith(color: color ?? context.glass.foregroundMuted),
            ),
            if (action case final button?) ...[
              const Gap(AppSpacing.lg),
              button,
            ],
          ],
        ),
      );
      return Center(
        child: constraints.hasBoundedHeight
            ? SingleChildScrollView(child: content)
            : content,
      );
    },
  );
}
