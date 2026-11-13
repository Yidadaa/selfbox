import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';

/// One interruptible transition keeps the mascot and input chrome in step.
class ChatComposerKeyboardTransition extends StatelessWidget {
  const ChatComposerKeyboardTransition({
    required this.editing,
    required this.child,
    super.key,
  });

  final bool editing;
  final Widget child;

  static double progressOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_KeyboardProgress>()?.value ??
      0;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: editing ? 1 : 0, end: editing ? 1 : 0),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.composerKeyboard,
    curve: AppMotion.composerKeyboardCurve,
    builder: (context, value, child) => _KeyboardProgress(
      value: value,
      child: child ?? const SizedBox.shrink(),
    ),
    child: child,
  );
}

class _KeyboardProgress extends InheritedWidget {
  const _KeyboardProgress({required this.value, required super.child});
  final double value;

  @override
  bool updateShouldNotify(_KeyboardProgress oldWidget) =>
      value != oldWidget.value;
}
