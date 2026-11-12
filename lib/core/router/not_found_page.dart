import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../gen/i18n/strings.g.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_canvas.dart';
import '../widgets/empty_state.dart';
import 'app_routes.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) => GlassScaffold(
    background: const AppCanvas(),
    body: EmptyState(
      label: context.t.notFound.title,
      action: const _BackHomeButton(),
    ),
  );
}

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
