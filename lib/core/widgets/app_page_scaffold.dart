import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../router/shell_scope.dart';
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
        title: Text(title),
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
