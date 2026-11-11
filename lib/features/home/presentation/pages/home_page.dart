import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_canvas.dart';
import '../../../../gen/assets/assets.gen.dart';
import '../../../../gen/i18n/strings.g.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return GlassScaffold(
      background: const AppCanvas(),
      appBar: GlassAppBar(title: Text(context.t.home.title)),
      // The body scrolls underneath the floating glass bar, so the list
      // insets itself instead of the scaffold doing it.
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          insets.top + AppSizes.appBarHeight + AppSpacing.md,
          AppSpacing.md,
          insets.bottom + AppSpacing.md,
        ),
        children: const [_WelcomeCard()],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final glass = context.glass;
    final textTheme = Theme.of(context).textTheme;
    return GlassContainer.card(
      padding: const EdgeInsets.all(AppSpacing.xl),
      shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Assets.images.logo.svg(
            width: AppSizes.iconHero,
            height: AppSizes.iconHero,
          ),
          const Gap(AppSpacing.md),
          Text(t.home.welcome, style: textTheme.titleLarge),
          const Gap(AppSpacing.xs),
          Text(
            t.home.subtitle,
            style: textTheme.bodyMedium?.copyWith(color: glass.foregroundMuted),
          ),
        ],
      ),
    );
  }
}
