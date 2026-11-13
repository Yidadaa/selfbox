import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../core/theme/app_motion.dart';

/// One interruptible transition keeps the mascot and input chrome in step.
class ChatComposerKeyboardTransition extends HookWidget {
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
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);
    final progress = useAnimationController(
      initialValue: editing ? 1 : 0,
      duration: AppMotion.composerKeyboard,
    );
    useEffect(() {
      final target = editing ? 1.0 : 0.0;
      if (disabled) {
        progress.value = target;
      } else {
        progress.animateTo(
          target,
          duration: AppMotion.composerKeyboard,
          curve: AppMotion.composerKeyboardCurve,
        );
      }
      return null;
    }, [editing, disabled, progress]);
    return _KeyboardProgress(value: useAnimation(progress), child: child);
  }
}

class _KeyboardProgress extends InheritedWidget {
  const _KeyboardProgress({required this.value, required super.child});
  final double value;

  @override
  bool updateShouldNotify(_KeyboardProgress oldWidget) =>
      value != oldWidget.value;
}
