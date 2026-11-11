import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../router/shell_scope.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_canvas.dart';

/// Standard page: canvas background, floating glass app bar, body that
/// scrolls underneath both bars.
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    required this.title,
    required this.body,
    this.leading,
    this.actions,
    super.key,
  });

  final String title;
  final Widget body;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      background: const AppCanvas(),
      appBar: GlassAppBar(
        title: _TitleCapsule(title: title),
        leading: leading,
        actions: actions,
      ),
      body: body,
    );
  }
}

/// Padding that keeps scrollable content clear of the floating app bar on
/// top and the tab bar (or home indicator) at the bottom.
abstract final class AppPageInsets {
  static EdgeInsets of(
    BuildContext context, {
    double horizontal = AppSpacing.md,
  }) {
    final top = MediaQuery.paddingOf(context).top;
    return EdgeInsets.fromLTRB(
      horizontal,
      top + AppSizes.appBarHeight + AppSpacing.md,
      horizontal,
      ShellScope.bottomInsetOf(context) + AppSpacing.md,
    );
  }
}

/// The page title sits in a small glass capsule (as in the reference
/// design) so it stays legible over content scrolling underneath.
class _TitleCapsule extends StatelessWidget {
  const _TitleCapsule({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.pill),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
