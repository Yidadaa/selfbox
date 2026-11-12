import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/logger/talker_provider.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/testing/scripted_language_model.dart';
import 'package:selfbox/features/chat/domain/models/agent_activity.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/assistant_controller.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/main.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

const _ready = AiSettings(
  providers: [
    ProviderConfig(
      id: 'p1',
      name: 'Gateway',
      format: ApiFormat.chatCompletions,
      baseUrl: 'https://gw.example.com/v1',
    ),
  ],
  models: [ModelConfig(providerId: 'p1', modelId: 'm1', enabled: true)],
);

final _question = Message(
  id: 1,
  createdAt: DateTime(2026, 11, 12, 9),
  author: MessageAuthor.me,
  text: '总结一下',
  askedAi: true,
);

typedef _Env = ({
  ProviderContainer container,
  FakeMessageRepository messages,
  ScriptedLanguageModel model,
  List<AssistantState> states,
  Talker talker,
});

_Env _env(
  List<List<Object>> steps, {
  AiSettings settings = _ready,
  Object? error,
}) {
  final model = ScriptedLanguageModel([
    for (final step in steps) step.cast(),
  ], error: error);
  final messages = FakeMessageRepository(seed: [_question]);
  final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
  final container = ProviderContainer(
    observers: [appRiverpodObserver(talker)],
    overrides: testAppOverrides(
      messages: messages,
      settings: FakeAiSettingsRepository(
        settings: settings,
        apiKeys: const {'p1': 'sk'},
      ),
      models: FakeLanguageModelFactory(model),
    )..add(talkerProvider.overrideWithValue(talker)),
  );
  addTearDown(container.dispose);
  final states = <AssistantState>[];
  container.listen(
    assistantControllerProvider,
    (_, next) => states.add(next),
    fireImmediately: true,
  );
  return (
    container: container,
    messages: messages,
    model: model,
    states: states,
    talker: talker,
  );
}

AssistantController _ctrl(_Env env) =>
    env.container.read(assistantControllerProvider.notifier);

void main() {
  test(
    'reset cancels and drains all pending replies before returning',
    () async {
      final env = _env([
        [scriptedText('late reply')],
      ]);
      final pending = _ctrl(env).ask(_question);
      await _ctrl(env).cancelAndWait();
      await pending;
      expect(env.messages.added, isEmpty);
      expect(env.states.last, const AssistantState.idle());
    },
  );
  group('AssistantController', () {
    test(
      'idle -> working(thinking -> tool -> typing) -> idle, reply stored',
      () async {
        final env = _env([
          [
            scriptedToolCall('search_messages', {'keywords': '总结'}),
          ],
          [scriptedText('**要点**：三件事。')],
        ]);

        await _ctrl(env).ask(_question);

        expect(env.states, [
          const AssistantState.idle(),
          const AssistantState.working(AgentActivity.thinking()),
          const AssistantState.working(
            AgentActivity.tool(AgentToolKind.searchMessages),
          ),
          const AssistantState.working(AgentActivity.thinking(segment: 1)),
          const AssistantState.working(AgentActivity.typing()),
          const AssistantState.idle(),
        ]);
        final reply = env.messages.added.last;
        expect(reply.author, MessageAuthor.ai);
        expect(reply.text, '**要点**：三件事。');
        final logs = env.talker.history
            .whereType<TalkerLog>()
            .map((entry) => entry.message.toString())
            .toList();
        expect(logs, contains('Agent #1 started message=1'));
        expect(logs, contains('Agent #1 tool search_messages started'));
        expect(logs, contains('Agent #1 tool search_messages succeeded'));
        expect(logs, contains('Agent #1 completed'));
        expect(logs.join(' '), isNot(contains(_question.text)));
        expect(logs.join(' '), isNot(contains('sk')));
      },
    );

    test('a failure keeps the question for retry and stores nothing', () async {
      final env = _env([], settings: const AiSettings());

      await _ctrl(env).ask(_question);

      expect(
        env.states.last,
        AssistantState.failed(
          const AppFailure.validation(message: AppFailure.noModel),
          _question,
        ),
      );
      expect(env.messages.added, isEmpty);
      expect(
        env.talker.history.whereType<TalkerLog>().last.message,
        'Agent #1 failed',
      );
    });

    test('stream previews never enter Riverpod logs', () async {
      const privatePreview = 'private preview text';
      final env = _env([
        [scriptedReasoning(privatePreview), scriptedText('done')],
      ]);

      await _ctrl(env).ask(_question);

      expect(
        env.states,
        contains(
          const AssistantState.working(
            AgentActivity.thinking(text: privatePreview),
          ),
        ),
      );
      final logText = env.talker.history
          .map((entry) => entry.message.toString())
          .join(' ');
      expect(env.talker.history.whereType<RiverpodAddLog>(), isNotEmpty);
      expect(logText, isNot(contains(privatePreview)));
    });

    test(
      'a tool-level failure is recorded without leaking its payload',
      () async {
        final env = _env([
          [
            scriptedToolCall('read_messages', {'id': 999}),
          ],
          [scriptedText('No matching note.')],
        ]);
        await _ctrl(env).ask(_question);
        final logs = env.talker.history
            .whereType<TalkerLog>()
            .map((entry) => entry.message.toString())
            .toList();
        expect(logs, contains('Agent #1 tool read_messages started'));
        expect(logs, contains('Agent #1 tool read_messages failed'));
        expect(logs.join(' '), isNot(contains('999')));
      },
    );

    test('retry re-asks the failed question', () async {
      final env = _env([
        [],
        [scriptedText('ok')],
      ], error: StateError('boom'));
      await _ctrl(env).ask(_question);
      expect(env.states.last, isA<AssistantFailed>());

      await _ctrl(env).retry();
      expect(env.states.last, const AssistantState.idle());
      expect(env.messages.added.last.text, 'ok');
    });

    test('dismiss clears a failure but not a running question', () async {
      final env = _env([], settings: const AiSettings());
      await _ctrl(env).ask(_question);
      _ctrl(env).dismiss();
      expect(env.states.last, const AssistantState.idle());
    });

    test('a newer question supersedes the running one', () async {
      final env = _env([
        [scriptedText('first')],
        [scriptedText('second')],
      ]);
      final first = _ctrl(env).ask(_question);
      final second = _ctrl(env).ask(_question.copyWith(text: 'again'));
      await Future.wait([first, second]);

      expect(env.states.last, const AssistantState.idle());
      // Only the latest question gets an answer posted.
      expect(
        env.messages.added.where((d) => d.author == MessageAuthor.ai),
        hasLength(1),
      );
    });
  });
}
