import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/features/chat/presentation/widgets/assistant_live_bubbles.dart';
import 'package:selfbox/features/chat/presentation/widgets/outgoing_message_entrance.dart';

void main() {
  testWidgets('stopping motion settles pending dots and entry exactly once', (
    tester,
  ) async {
    final disabled = ValueNotifier(false);
    addTearDown(disabled.dispose);
    var completed = 0;
    await tester.pumpPage(
      ValueListenableBuilder(
        valueListenable: disabled,
        builder: (_, value, child) => MediaQuery(
          data: MediaQueryData(disableAnimations: value),
          child: child!,
        ),
        child: Column(
          children: [
            const AssistantTypingBubble(label: 'Typing'),
            OutgoingMessageEntrance(
              onComplete: () => completed++,
              child: const SizedBox(width: 120, height: 48),
            ),
          ],
        ),
      ),
      settle: false,
    );
    expect(tester.binding.hasScheduledFrame, isTrue);
    disabled.value = true;
    await tester.pumpAndSettle();
    expect(completed, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
    for (var i = 0; i < 3; i++) {
      final transform = tester.widget<Transform>(
        find.byKey(ValueKey('typing-dot-$i')),
      );
      expect(transform.transform.getTranslation().y, 0);
    }
    disabled.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.binding.hasScheduledFrame, isTrue);
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
