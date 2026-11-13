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
      for (var index = 0; index < 3; index++) {
        expect(find.byKey(ValueKey('pending-dot-$index')), findsOneWidget);
      }
      final pendingDot = find.byKey(const ValueKey('pending-dot-0'));
      final initialOffset = tester
          .widget<Transform>(pendingDot)
          .transform
          .getTranslation()
          .y;
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester.widget<Transform>(pendingDot).transform.getTranslation().y,
        isNot(initialOffset),
      );
      // Sits below the question (reversed list: bottom is newest).
      expect(
        tester.getTopLeft(find.byType(AssistantStatusBubble)).dy,
        greaterThan(tester.getTopLeft(find.text(_question.text)).dy),
      );
    });

    testWidgets('typing shows only a label and three animated dots', (
      tester,
    ) async {
      await _showState(
        tester,
        const AssistantState.working(AgentActivity.typing()),
      );

      expect(find.bySemanticsLabel(t.assistant.typing), findsOneWidget);
      expect(find.text(t.assistant.typing), findsOneWidget);
      expect(find.byType(StreamMarkdown), findsNothing);
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('typing-dot-$i')), findsOneWidget);
      }
      final dot = find.byKey(const ValueKey('typing-dot-0'));
      final first = tester.widget<Transform>(dot).transform.getTranslation().y;
      await tester.pump(const Duration(milliseconds: 70));
      await tester.pump(const Duration(milliseconds: 70));
      expect(
        tester.widget<Transform>(dot).transform.getTranslation().y,
        isNot(first),
      );
    });

    for (final brightness in Brightness.values) {
      testWidgets(
        'reasoning renders Markdown in a fading three-line window in $brightness',
        (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
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
              AgentActivity.thinking(
                text: '# 标题\n\n第一行\n\n第二行\n\n**第三行**\n\n第四行',
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.byType(StreamMarkdown), findsOneWidget);
          expect(find.text(t.assistant.thinking), findsOneWidget);
          expect(find.byKey(const ValueKey('pending-dot-0')), findsNothing);
          expect(
            find.byKey(const ValueKey('thinking-viewport')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('assistant-pending-surface')),
            findsNothing,
          );
          expect(
            tester.widget<SmoothMarkdown>(find.byType(SmoothMarkdown)).data,
            contains('第四行'),
          );
          expect(find.byKey(const ValueKey('thinking-fade')), findsOneWidget);
          final viewport = find.byKey(const ValueKey('thinking-viewport'));
          expect(tester.getSize(viewport).height, lessThanOrEqualTo(80));
          final scroll = tester.widget<SingleChildScrollView>(
            find.byKey(const ValueKey('thinking-scroll')),
          );
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pump(const Duration(milliseconds: 200));
          expect(
            scroll.controller!.offset,
            closeTo(scroll.controller!.position.maxScrollExtent, 1),
          );
          final sheet = tester
              .widget<StreamMarkdown>(find.byType(StreamMarkdown))
              .styleSheet!;
          expect(sheet.h1Style!.fontSize, sheet.paragraphStyle!.fontSize);
          expect(sheet.h1Style!.fontWeight, FontWeight.w600);
          expect(tester.takeException(), isNull);

          controller.show(
            const AssistantState.working(
              AgentActivity.thinking(
                text: '# 标题\n\n第一行\n\n第二行\n\n**第三行**\n\n第四行\n\n继续思考',
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 100));
          expect(
            tester.widget<SmoothMarkdown>(find.byType(SmoothMarkdown)).data,
            contains('继续思考'),
          );
          await tester.pump(const Duration(milliseconds: 200));
          await tester.pump(const Duration(milliseconds: 200));
          expect(
            scroll.controller!.offset,
            closeTo(scroll.controller!.position.maxScrollExtent, 1),
          );

          controller.show(const AssistantState.working(AgentActivity.typing()));
          await tester.pump(const Duration(milliseconds: 20));
          await tester.pump(const Duration(milliseconds: 600));
          expect(find.text(t.assistant.typing), findsOneWidget);
          expect(find.byType(StreamMarkdown), findsNothing);
          expect(find.byType(SmoothMarkdown), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
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
