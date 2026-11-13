import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/theme/app_motion.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/features/chat/domain/models/agent_activity.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/assistant_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/assistant_status_bubble.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';
import 'package:selfbox/features/chat/presentation/widgets/outgoing_message_entrance.dart';

class _FinishingAssistant extends AssistantController {
  @override
  AssistantState build() =>
      const AssistantState.working(AgentActivity.typing());

  void finish() => state = const AssistantState.idle();
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('new AI answer stays at the status left edge in $brightness', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final messages = FakeMessageRepository(
        clock: () => kTestNow.add(const Duration(minutes: 1)),
        seed: [
          Message(
            id: 1,
            createdAt: kTestNow,
            author: MessageAuthor.me,
            text: 'Question',
          ),
        ],
      );
      final container = await tester.pumpApp(
        messages: messages,
        overrides: [
          assistantControllerProvider.overrideWith(_FinishingAssistant.new),
        ],
        settle: false,
      );
      final anchor = tester.getTopLeft(find.byType(AssistantStatusBubble)).dx;
      final result = await messages
          .add(
            const MessageDraft(
              author: MessageAuthor.ai,
              text: 'This answer stays anchored to the same left edge.',
            ),
          )
          .run();
      final reply = result.getOrElse((failure) => throw StateError('$failure'));
      container.read(assistantReplyEventProvider.notifier).publish(reply.id);
      (container.read(
        assistantControllerProvider.notifier,
      ) as _FinishingAssistant).finish();
      await tester.pump();
      await tester.pump();
      for (
        var frame = 0;
        frame < 10 && find.byType(OutgoingMessageEntrance).evaluate().isEmpty;
        frame++
      ) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      final surface = find.descendant(
        of: find.byWidgetPredicate(
          (widget) => widget is MessageBubble && widget.message.id == reply.id,
        ),
        matching: find.byKey(const ValueKey('message-surface')),
      );
      expect(find.byType(OutgoingMessageEntrance), findsOneWidget);
      expect(anchor, AppSpacing.md);
      for (
        var elapsed = Duration.zero;
        elapsed <= AppMotion.messageSend + const Duration(milliseconds: 32);
        elapsed += const Duration(milliseconds: 16)
      ) {
        expect(
          tester.getTopLeft(surface).dx,
          closeTo(anchor, 0.01),
          reason: 'AI answer shifted sideways at $elapsed',
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.byType(OutgoingMessageEntrance), findsNothing);
      expect(find.byType(AssistantStatusBubble), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
