import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../router/shell_scope.dart';
import '../theme/app_glass_theme.dart';
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
    this.titleContent,
    this.appBarHeight = AppSizes.appBarHeight,
    this.resizeToAvoidBottomInset = true,
    super.key,
  });

  final String title;
  final Widget body;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? titleContent;
  final double appBarHeight;

  /// Turn off when the page positions content against the keyboard itself;
  /// otherwise the body shrinks *and* the content lifts, counting it twice.
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      background: const AppCanvas(),
      backgroundColor: context.glass.canvasGradient.first,
      topEdgeFade: false,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: GlassAppBar(
        title: titleContent ?? _TitleCapsule(title: title),
        leading: leading,
        actions: actions,
        toolbarHeight: appBarHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppInsets.pageHorizontal,
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          body,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height:
                MediaQuery.paddingOf(context).top +
                appBarHeight +
                AppSpacing.lg,
            child: IgnorePointer(
              key: const ValueKey('app-top-fade'),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.glass.canvasGradient.first,
                      context.glass.canvasGradient.first.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Padding that keeps scrollable content clear of the floating app bar on
/// top and the tab bar (or home indicator) at the bottom.
abstract final class AppPageInsets {
  static EdgeInsets of(
    BuildContext context, {
    double horizontal = AppInsets.pageHorizontal,
    double appBarHeight = AppSizes.appBarHeight,
  }) {
    final top = MediaQuery.paddingOf(context).top;
    return EdgeInsets.fromLTRB(
      horizontal,
      top + appBarHeight + AppSpacing.md,
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
      key: const ValueKey('page-title-capsule'),
      shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.pill),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        child: Center(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
