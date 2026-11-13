import 'package:flutter/material.dart';

import 'chat_composer_keyboard_transition.dart';

class ChatComposerTabs extends StatelessWidget {
  const ChatComposerTabs({
    required this.keyboardOpen,
    required this.navigation,
    super.key,
  });

  final bool keyboardOpen;
  final Widget? navigation;

  @override
  Widget build(BuildContext context) {
    final visible = 1 - ChatComposerKeyboardTransition.progressOf(context);
    if (keyboardOpen && visible == 0) return const SizedBox.shrink();
    return IgnorePointer(
      ignoring: keyboardOpen || visible < 1,
      child: ExcludeSemantics(
        excluding: keyboardOpen || visible < 1,
        child: ClipRect(
          key: const ValueKey('composer-tabs-reveal'),
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: visible,
            child: Opacity(
              opacity: visible,
              child: navigation ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
