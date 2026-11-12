import 'package:flutter/widgets.dart';

/// Space occupied by the measured dock and keyboard below every tab page.
///
/// Tab pages extend underneath the glass bar, so scrollable bodies pad their
/// trailing edge by this amount instead of guessing the bar's height.
class ShellScope extends InheritedWidget {
  const ShellScope({
    required this.bottomInset,
    required super.child,
    super.key,
  });

  final double bottomInset;

  /// Falls back to the safe-area inset for pages shown outside the shell
  /// (full-screen routes, widget tests).
  static double bottomInsetOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>()?.bottomInset ??
      MediaQuery.paddingOf(context).bottom;

  @override
  bool updateShouldNotify(ShellScope oldWidget) =>
      bottomInset != oldWidget.bottomInset;
}
