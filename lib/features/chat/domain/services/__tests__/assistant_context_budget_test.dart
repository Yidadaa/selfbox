import 'dart:typed_data';

import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/testing/fake_account_repository.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/core/testing/fake_memory_repository.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/testing/scripted_language_model.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/domain/services/assistant_agent.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';

const _provider = ProviderConfig(
  id: 'p',
  name: 'Test',
  format: ApiFormat.chatCompletions,
  baseUrl: 'https://example.com/v1',
);

Message _note(int id, String text) => Message(
  id: id,
  createdAt: DateTime(2026, 11, 13).add(Duration(minutes: id)),
  author: MessageAuthor.me,
  text: text,
);

Future<String> _prompt({
  required List<Message> notes,
  AiSettings settings = const AiSettings(
    providers: [_provider],
    models: [ModelConfig(providerId: 'p', modelId: 'm', enabled: true)],
  ),
}) async {
  final question = _note(1000, 'current question');
  final model = ScriptedLanguageModel([
    [scriptedText('ok')],
  ]);
  final agent = AssistantAgent(
    settings: FakeAiSettingsRepository(settings: settings, apiKeys: {'p': 'k'}),
    account: FakeAccountRepository(),
    messages: FakeMessageRepository(seed: [...notes, question]),
    memory: FakeMemoryRepository(),
    readImage: (_) => TaskEither.right(Uint8List(0)),
    models: FakeLanguageModelFactory(model),
    clock: () => question.createdAt,
    languageTag: () => 'en',
    defaultAgentName: () => 'Dozy',
  );
  expect(
    (await agent.answer(question, onActivity: (_) {}).run()).isRight(),
    isTrue,
  );
  return model.calls.single.prompt.messages
      .expand((message) => message.content)
      .whereType<LanguageModelV4TextPart>()
      .map((part) => part.text)
      .join();
}

void main() {
  test(
    'fills context with short notes beyond the old message-count limit',
    () async {
      final prompt = await _prompt(
        notes: [for (var id = 1; id <= 150; id++) _note(id, 'note-$id')],
      );
      expect(prompt, contains('note-1\n'));
      expect(prompt, contains('note-150'));
      expect(prompt, contains('current question'));
    },
  );

  for (final (percent, included) in [(10, 1), (20, 2), (60, 7)]) {
    test(
      'request fills $percent percent of full context from the newest notes',
      () async {
        final prompt = await _prompt(
          settings: AiSettings(
            providers: const [_provider],
            models: const [
              ModelConfig(
                providerId: 'p',
                modelId: 'm',
                enabled: true,
                maxOutputTokens: 1000,
              ),
            ],
            shortTermMemoryPercent: percent,
          ),
          notes: [
            for (var id = 1; id <= 8; id++)
              _note(id, 'history-$id ${'汉' * 10000}'),
          ],
        );
        for (var id = 1; id <= 8; id++) {
          expect(prompt.contains('history-$id '), id > 8 - included);
        }
        expect(prompt, contains('current question'));
      },
    );
  }

  test(
    'reserves input space for instructions and output outside the percentage',
    () async {
      final prompt = await _prompt(
        settings: const AiSettings(
          providers: [_provider],
          models: [
            ModelConfig(
              providerId: 'p',
              modelId: 'm',
              enabled: true,
              maxOutputTokens: 127500,
            ),
          ],
          shortTermMemoryPercent: 60,
        ),
        notes: [_note(1, 'older note that must not crowd out instructions')],
      );
      expect(prompt, isNot(contains('older note')));
      expect(prompt, contains('current question'));
    },
  );
}
