import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/domain/services/agent_prompt.dart';
import 'package:selfbox/features/chat/domain/services/agent_references.dart';

import '../../../../support/fake_message_repository.dart';
import '../../../../support/scripted_language_model.dart';
import 'assistant_agent_test_support.dart';

void main() {
  test(
    'actual model request contains referenced originals and their roles',
    () async {
      final env = createAgentTestEnv([
        [scriptedText('ok')],
      ]);
      final question = agentTestQuestion.copyWith(quotedMessageIds: [1, 2]);
      final result = await env.agent
          .answer(question, onActivity: env.activity.add)
          .run();
      expect(result.isRight(), true);
      final text = env.model.calls.single.prompt.messages
          .expand((message) => message.content)
          .whereType<LanguageModelV4TextPart>()
          .map((part) => part.text)
          .join();
      expect(text, contains('[引用 #1, #2]'));
      expect(text, contains('Referenced messages'));
      expect(text, contains('"text":"买牛奶和面包"'));
      expect(text, contains('"images":1'));
    },
  );
  final source = Message(
    id: 1,
    createdAt: DateTime(2026),
    author: MessageAuthor.ai,
    text: 'original answer',
    quotedMessageIds: const [10],
  );
  final question = source.copyWith(
    id: 100,
    author: MessageAuthor.me,
    text: 'compare',
    quotedMessageIds: [1, 2, 1],
  );
  test('loads unique originals outside recent history, preserving nested relations', () async {
    final repo = FakeMessageRepository(seed: [source]);
    final result = await loadAgentReferences(
      messages: repo,
      question: question,
      budget: 1000,
    ).run();
    final references = result.toNullable() ?? [];
    expect(references, [source]);
    final text = buildAgentHistory([
      question,
    ], references: references).single.text;
    expect(text, contains('original answer'));
    expect(text, contains('"author":"ai"'));
    expect(text, contains('"quoted_message_ids":[10]'));
    expect(text, contains('[引用 #1, #2, #1]'));
  });
  test(
    'oversized originals use relation IDs without exceeding the budget',
    () async {
      final repo = FakeMessageRepository(
        seed: [source.copyWith(text: '中' * 5000)],
      );
      final result = await loadAgentReferences(
        messages: repo,
        question: question,
        budget: 10,
      ).run();
      expect(result.toNullable(), isEmpty);
      expect(formatAgentReferences([]), '');
    },
  );
}
