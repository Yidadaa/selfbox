import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/theme/app_motion.dart';
import 'package:selfbox/features/chat/data/chat_data_providers.dart';
import 'package:selfbox/features/chat/domain/models/agent_activity.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/assistant_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/assistant_status_bubble.dart';
import 'package:selfbox/features/chat/presentation/widgets/outgoing_message_entrance.dart';

import 'screenshot_fixtures.dart';

const _thinking = AgentActivity.thinking(
  text: '先查找这周记录的待办，再按时间整理。\n\n还需要确认哪些已经完成。',
);

const _stages = <(String, AgentActivity, AgentActivity?)>[
  (
    'thinking_tool',
    _thinking,
    AgentActivity.tool(AgentToolKind.searchMessages),
  ),
  (
    'tool_thinking',
    AgentActivity.tool(AgentToolKind.searchMessages),
    _thinking,
  ),
  (
    'tool_typing',
    AgentActivity.tool(AgentToolKind.readMessages),
    AgentActivity.typing(),
  ),
  ('reply', AgentActivity.typing(), null),
];

class _TransitionAssistant extends AssistantController {
  _TransitionAssistant(this.initial);

  final AgentActivity initial;

  @override
  AssistantState build() => AssistantState.working(initial);

  void show(AgentActivity activity) => state = AssistantState.working(activity);

  void finish() => state = const AssistantState.idle();
}

ScreenshotEnv _environment(AgentActivity initial) => (
  paths: null,
  messages: FakeMessageRepository(
    clock: () => kTestNow.add(const Duration(minutes: 1)),
    seed: [
      Message(
        id: 1,
        createdAt: kTestNow,
        author: MessageAuthor.me,
        text: '我这周都记了哪些待办？',
        askedAi: true,
      ),
    ],
  ),
  memory: null,
  settings: null,
  overrides: [
    assistantControllerProvider.overrideWith(
      () => _TransitionAssistant(initial),
    ),
  ],
);

Future<void> _captureTransition(
  WidgetTester tester,
  AgentActivity? next,
) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(AssistantStatusBubble)),
  );
  final assistant = container.read(
    assistantControllerProvider.notifier,
  ) as _TransitionAssistant;
  if (next case final activity?) {
    assistant.show(activity);
    await tester.pump();
    await tester.pump(AppMotion.statusTransition ~/ 3);
    return;
  }

  final result = await container
      .read(messageRepositoryProvider)
      .add(
        const MessageDraft(
          author: MessageAuthor.ai,
          text:
              '这周你记下了 **3 件待办**：\n\n'
              '- 回复客户邮件\n- 提交周报\n- 完成季度复盘',
        ),
      )
      .run();
  final reply = result.getOrElse((failure) => throw StateError('$failure'));
  container.read(assistantReplyEventProvider.notifier).publish(reply.id);
  assistant.finish();
  for (var frame = 0; frame < 10; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (find.byType(OutgoingMessageEntrance).evaluate().isNotEmpty) break;
  }
  expect(find.byType(OutgoingMessageEntrance), findsOneWidget);
  await tester.pump(AppMotion.messageSend ~/ 3);
}

final assistantTransitionFixtures = [
  for (final brightness in Brightness.values)
    for (final (name, initial, next) in _stages)
      ScreenshotFixture(
        name: 'assistant_transition_${name}_${brightness.name}',
        location: '/chat',
        animated: true,
        env: () => _environment(initial),
        setUp: (tester, _) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await tester.pump();
        },
        afterOpen: (tester) => _captureTransition(tester, next),
      ),
];
