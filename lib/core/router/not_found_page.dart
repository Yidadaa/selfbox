import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../gen/i18n/strings.g.dart';
import '../theme/app_glass_theme.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_canvas.dart';
import 'app_routes.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassScaffold(
      background: AppCanvas(),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [_NotFoundCard(), Gap(AppSpacing.xl), _BackHomeButton()],
          ),
        ),
      ),
    );
  }
}

class _NotFoundCard extends StatelessWidget {
  const _NotFoundCard();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final glass = context.glass;
    final textTheme = Theme.of(context).textTheme;
    return GlassContainer.card(
      padding: const EdgeInsets.all(AppSpacing.xl),
      shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.explore_off_rounded,
            size: AppSizes.iconHero,
            color: glass.foregroundMuted,
          ),
          const Gap(AppSpacing.md),
          Text(t.notFound.title, style: textTheme.titleLarge),
        ],
      ),
    );
  }
}

// Sits outside the card: refractive controls must never nest inside a
// refractive container (double refraction + clipped spring animation).
class _BackHomeButton extends StatelessWidget {
  const _BackHomeButton();

  @override
  Widget build(BuildContext context) {
    return GlassButton.custom(
      height: AppSizes.minTouchTarget,
      shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.pill),
      label: context.t.notFound.backHome,
      onTap: () {
        HapticFeedback.lightImpact();
        const ChatRoute().go(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Center(widthFactor: 1, child: Text(context.t.notFound.backHome)),
      ),
    );
  }
}
