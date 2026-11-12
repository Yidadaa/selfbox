import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/testing/scripted_language_model.dart';
import 'package:selfbox/features/chat/domain/models/agent_activity.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/assistant_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/assistant_status_bubble.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/presentation/pages/ai_providers_page.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

final _question = Message(
  id: 1,
  createdAt: kTestNow,
  author: MessageAuthor.me,
  text: '上周买了什么？',
  askedAi: true,
);

class _Fixed extends AssistantController {
  _Fixed(this.initial);

  final AssistantState initial;

  @override
  AssistantState build() => initial;

  void show(AssistantState next) => state = next;
}

Future<void> _showState(WidgetTester tester, AssistantState state) =>
    tester.pumpApp(
      messages: FakeMessageRepository(seed: [_question]),
      overrides: [
        assistantControllerProvider.overrideWith(() => _Fixed(state)),
      ],
      settle: false,
    );

void main() {
  group('AI mode in the chat timeline', () {
    testWidgets('shows only the latest tool as a single pending bubble', (
      tester,
    ) async {
      await _showState(
        tester,
        const AssistantState.working(
          AgentActivity.tool(AgentToolKind.searchMessages),
        ),
      );

      expect(find.byType(AssistantStatusBubble), findsOneWidget);
      expect(find.text(t.assistant.searching), findsOneWidget);
      expect(find.text(t.assistant.thinking), findsNothing);
      // Sits below the question (reversed list: bottom is newest).
      expect(
        tester.getTopLeft(find.byType(AssistantStatusBubble)).dy,
        greaterThan(tester.getTopLeft(find.text(_question.text)).dy),
      );
    });

    testWidgets('shows a plain single-line fallback while awaiting text', (
      tester,
    ) async {
      await _showState(
        tester,
        const AssistantState.working(AgentActivity.typing()),
      );

      expect(find.bySemanticsLabel(t.assistant.typing), findsOneWidget);
      expect(find.text(t.assistant.typing), findsOneWidget);
      expect(find.byType(SmoothMarkdown), findsNothing);
    });

    for (final brightness in Brightness.values) {
      testWidgets('live lines stay bounded and animate in $brightness', (
        tester,
      ) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final container = await tester.pumpApp(
          messages: FakeMessageRepository(seed: [_question]),
          overrides: [
            assistantControllerProvider.overrideWith(
              () => _Fixed(
                const AssistantState.working(AgentActivity.thinking()),
              ),
            ),
          ],
          settle: false,
        );
        tester.view.physicalSize = const Size(280 * 3, 640 * 3);
        await tester.pump();

        final controller =
            container.read(assistantControllerProvider.notifier) as _Fixed;
        controller.show(
          const AssistantState.working(
            AgentActivity.thinking(line: '最新的一行思考内容会非常非常长'),
          ),
        );
        await tester.pump();
        final preview = find.text('最新的一行思考内容会非常非常长');
        expect(preview, findsOneWidget);
        expect(tester.widget<Text>(preview).maxLines, 1);
        expect(find.byType(SmoothMarkdown), findsNothing);
        expect(tester.takeException(), isNull);

        final cursor = find.byKey(const ValueKey('live-progress'));
        final firstOpacity = tester
            .widget<FadeTransition>(cursor)
            .opacity
            .value;
        await tester.pump(const Duration(milliseconds: 140));
        expect(
          tester.widget<FadeTransition>(cursor).opacity.value,
          isNot(firstOpacity),
        );

        controller.show(
          const AssistantState.working(AgentActivity.thinking(line: '继续思考')),
        );
        await tester.pump(const Duration(milliseconds: 20));
        expect(preview, findsNothing);
        expect(find.text('继续思考'), findsOneWidget);

        controller.show(
          const AssistantState.working(AgentActivity.typing(line: '最新的回复内容')),
        );
        await tester.pump(const Duration(milliseconds: 20));
        expect(find.text('最新的回复内容'), findsOneWidget);
        expect(find.byType(SmoothMarkdown), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a missing model offers setup, which opens AI providers', (
      tester,
    ) async {
      await _showState(
        tester,
        AssistantState.failed(
          const AppFailure.validation(message: AppFailure.noModel),
          _question,
        ),
      );

      expect(find.text(t.settings.errors.noModel), findsOneWidget);
      await tester.tap(find.text(t.assistant.setup));
      await tester.pumpAndSettle();
      expect(find.byType(AiProvidersPage), findsOneWidget);
    });

    testWidgets('network failures offer retry and can be dismissed', (
      tester,
    ) async {
      await _showState(
        tester,
        AssistantState.failed(
          const AppFailure.network(message: 'x'),
          _question,
        ),
      );

      expect(find.text(t.settings.errors.network), findsOneWidget);
      expect(find.text(t.common.retry), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(t.assistant.dismiss));
      await tester.pumpAndSettle();
      expect(find.byType(AssistantStatusBubble), findsNothing);
    });

    testWidgets(
      'sending in AI mode posts the full reply as rendered markdown',
      (tester) async {
        final messages = FakeMessageRepository();
        final container = await tester.pumpApp(
          messages: messages,
          settings: FakeAiSettingsRepository(
            settings: const AiSettings(
              providers: [
                ProviderConfig(
                  id: 'p1',
                  name: 'Gateway',
                  format: ApiFormat.chatCompletions,
                  baseUrl: 'https://gw.example.com/v1',
                ),
              ],
              models: [
                ModelConfig(providerId: 'p1', modelId: 'm1', enabled: true),
              ],
            ),
            apiKeys: const {'p1': 'sk'},
          ),
          models: FakeLanguageModelFactory(
            ScriptedLanguageModel([
              [scriptedText('你买了**牛奶**。')],
            ]),
          ),
        );
        expect(
          container.read(appRouterProvider).state.matchedLocation,
          '/chat',
        );

        await tester.tap(find.bySemanticsLabel(t.chat.aiMode));
        await tester.pump();
        await tester.enterText(
          find.descendant(
            of: find.byType(ChatComposer),
            matching: find.byType(EditableText),
          ),
          '上周买了什么？',
        );
        await tester.pump();
        await tester.tap(find.bySemanticsLabel(t.chat.send));
        // The SDK's stream pipeline needs real event-loop turns, which
        // fake async never gives; interleave short real-time slices.
        for (var i = 0; i < 50 && messages.added.length < 2; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();

        expect(messages.added.first.askedAi, isTrue);
        expect(messages.added.last.author, MessageAuthor.ai);
        expect(find.byType(SmoothMarkdown), findsOneWidget);
        expect(find.byType(AssistantStatusBubble), findsNothing);
      },
    );
  });
}
