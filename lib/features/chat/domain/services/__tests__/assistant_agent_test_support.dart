import 'dart:typed_data';

import 'package:ai_sdk_provider/ai_sdk_provider.dart';
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

const agentTestProvider = ProviderConfig(
  id: 'p1',
  name: 'Gateway',
  format: ApiFormat.chatCompletions,
  baseUrl: 'https://gw.example.com/v1',
);

AiSettings agentTestSettings({bool images = false}) => AiSettings(
  providers: const [agentTestProvider],
  models: [
    ModelConfig(
      providerId: 'p1',
      modelId: 'm1',
      enabled: true,
      supportsImages: images,
      maxOutputTokens: 1000,
    ),
  ],
);

final agentTestQuestion = Message(
  id: 3,
  createdAt: DateTime(2026, 11, 12, 9),
  author: MessageAuthor.me,
  text: '我上周说要买什么？',
  askedAi: true,
);

typedef AgentTestEnv = ({
  AssistantAgent agent,
  ScriptedLanguageModel model,
  FakeLanguageModelFactory factory,
  FakeMemoryRepository memory,
  List<AgentActivity> activity,
});

AgentTestEnv createAgentTestEnv(
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
      settings: settings ?? agentTestSettings(),
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
        agentTestQuestion,
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

Future<Either<AppFailure, String>> askTestAgent(AgentTestEnv env) =>
    env.agent.answer(agentTestQuestion, onActivity: env.activity.add).run();
