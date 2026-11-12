import 'dart:typed_data';

import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/fake_account_repository.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/core/testing/fake_memory_repository.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/testing/scripted_language_model.dart';
import 'package:selfbox/features/chat/domain/models/agent_activity.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/domain/services/assistant_agent.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';

const _provider = ProviderConfig(
  id: 'p1',
  name: 'Gateway',
  format: ApiFormat.chatCompletions,
  baseUrl: 'https://gw.example.com/v1',
);

AiSettings _settings({bool images = false, int history = 20}) => AiSettings(
  providers: const [_provider],
  models: [
    ModelConfig(
      providerId: 'p1',
      modelId: 'm1',
      enabled: true,
      supportsImages: images,
      maxOutputTokens: 1000,
    ),
  ],
  historyTurns: history,
);

final _question = Message(
  id: 3,
  createdAt: DateTime(2026, 11, 12, 9),
  author: MessageAuthor.me,
  text: '我上周说要买什么？',
  askedAi: true,
);

typedef _Env = ({
  AssistantAgent agent,
  ScriptedLanguageModel model,
  FakeLanguageModelFactory factory,
  FakeMemoryRepository memory,
  List<AgentActivity> activity,
});

_Env _env(
  List<List<LanguageModelV4ContentPart>> steps, {
  AiSettings? settings,
  Map<String, String> keys = const {'p1': 'sk'},
  Object? error,
}) {
  final model = ScriptedLanguageModel(steps, error: error);
  final factory = FakeLanguageModelFactory(model);
  final memory = FakeMemoryRepository();
  final agent = AssistantAgent(
    settings: FakeAiSettingsRepository(
      settings: settings ?? _settings(),
      apiKeys: keys,
    ),
    account: FakeAccountRepository(),
    messages: FakeMessageRepository(
      seed: [
        Message(
          id: 1,
          createdAt: DateTime(2026, 11, 5, 8),
          author: MessageAuthor.me,
          text: '买牛奶和面包',
        ),
        Message(
          id: 2,
          createdAt: DateTime(2026, 11, 6, 8),
          author: MessageAuthor.me,
          text: '',
          images: const ['media/a.png'],
        ),
        _question,
      ],
    ),
    memory: memory,
    readImage: (_) => TaskEither.right(Uint8List.fromList([1, 2, 3])),
    models: factory,
    clock: () => DateTime(2026, 11, 12, 9, 1),
    languageTag: () => 'zh-CN',
  );
  return (
    agent: agent,
    model: model,
    factory: factory,
    memory: memory,
    activity: <AgentActivity>[],
  );
}

Future<Either<AppFailure, String>> _ask(_Env env) =>
    env.agent.answer(_question, onActivity: env.activity.add).run();

void main() {
  group('AssistantAgent', () {
    test('answers directly when no tools are needed', () async {
      final env = _env([
        [scriptedText('你说过要买牛奶和面包。')],
      ]);

      expect((await _ask(env)).toNullable(), '你说过要买牛奶和面包。');
      expect(env.activity, [
        const AgentActivity.thinking(),
        const AgentActivity.typing(),
      ]);
      expect(env.factory.created.single.apiKey, 'sk');
      expect(env.factory.created.single.modelId, 'm1');
      expect(env.factory.disposed, 1);
    });

    test('sends instructions, history and budgets to the model', () async {
      final env = _env([
        [scriptedText('ok')],
      ]);
      await _ask(env);

      final call = env.model.calls.single;
      expect(call.maxOutputTokens, 1000);
      expect(call.prompt.system, contains('Selfbox'));
      final userText = call.prompt.messages
          .where((m) => m.role == LanguageModelV4Role.user)
          .expand((m) => m.content)
          .whereType<LanguageModelV4TextPart>()
          .map((p) => p.text)
          .join();
      expect(userText, contains('[#1 2026-11-05 08:00] 买牛奶和面包'));
      expect(userText, contains('我上周说要买什么？'));
      expect(call.tools.map((t) => t.name), contains('search_messages'));
      expect(call.tools.map((t) => t.name), isNot(contains('view_image')));
    });

    test(
      'runs a multi-step tool loop and reports only the latest tool',
      () async {
        final env = _env([
          [
            scriptedToolCall('search_messages', {'keywords': '买'}, id: 's1'),
          ],
          [
            scriptedToolCall('memory_create', {
              'path': 'topic/shopping.md',
              'content': '# 购物\n- 牛奶、面包',
            }, id: 'c1'),
          ],
          [scriptedText('上周你记了：买牛奶和面包。')],
        ]);

        final answer = await _ask(env);

        expect(answer.toNullable(), '上周你记了：买牛奶和面包。');
        expect(env.model.calls, hasLength(3));
        expect(env.activity, [
          const AgentActivity.thinking(),
          const AgentActivity.tool(AgentToolKind.searchMessages),
          const AgentActivity.tool(AgentToolKind.writeMemory),
          const AgentActivity.typing(),
        ]);
        expect(env.memory.contentOf('topic/shopping.md'), contains('牛奶'));

        // The second request carries the first tool's result.
        final toolResults = env.model.calls[1].prompt.messages
            .expand((m) => m.content)
            .whereType<LanguageModelV4ToolResultPart>();
        expect(toolResults.single.toolName, 'search_messages');
      },
    );

    test('attaches a viewed image right after the view_image result', () async {
      final env = _env([
        [
          scriptedToolCall('view_image', {'message_id': 2}, id: 'v1'),
        ],
        [scriptedText('是一张极光照片。')],
      ], settings: _settings(images: true));

      expect((await _ask(env)).toNullable(), '是一张极光照片。');
      final messages = env.model.calls[1].prompt.messages;
      final resultIndex = messages.indexWhere(
        (m) => m.content.whereType<LanguageModelV4ToolResultPart>().isNotEmpty,
      );
      final next = messages[resultIndex + 1];
      expect(next.role, LanguageModelV4Role.user);
      final image = next.content.single as LanguageModelV4ImagePart;
      expect(image.mediaType, 'image/png');
      expect((image.image as DataContentBytes).bytes, [1, 2, 3]);
    });

    test('limits history to the configured number of turns', () async {
      final env = _env([
        [scriptedText('ok')],
      ], settings: _settings(history: 0));
      await _ask(env);

      final userText = env.model.calls.single.prompt.messages
          .expand((m) => m.content)
          .whereType<LanguageModelV4TextPart>()
          .map((p) => p.text)
          .join();
      expect(userText, isNot(contains('买牛奶')));
      expect(userText, contains('我上周说要买什么？'));
    });

    test('fails fast without an enabled model', () async {
      final env = _env([], settings: const AiSettings());
      final failure = (await _ask(env)).getLeft().toNullable();

      expect(
        failure,
        const AppFailure.validation(message: AssistantAgent.noModel),
      );
      expect(env.factory.created, isEmpty);
      expect(env.activity, isEmpty);
    });

    test('fails fast without an API key', () async {
      final env = _env([], keys: const {});
      expect(
        (await _ask(env)).getLeft().toNullable(),
        const AppFailure.validation(message: AppFailure.missingApiKey),
      );
    });

    test('maps provider HTTP errors to network failures', () async {
      final env = _env(
        [],
        error: const AiApiCallError('bad key', statusCode: 401),
      );
      final failure = (await _ask(env)).getLeft().toNullable();

      expect(failure, isA<NetworkFailure>());
      expect((failure! as NetworkFailure).statusCode, 401);
      expect(env.factory.disposed, 1);
    });

    test('an empty final answer is a failure, not a blank bubble', () async {
      final env = _env([
        [scriptedText('   ')],
      ]);
      expect((await _ask(env)).getLeft().toNullable(), isA<NetworkFailure>());
    });
  });
}
