import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/domain/services/agent_history.dart';
import 'package:selfbox/features/chat/domain/services/agent_prompt.dart';

Message _note(
  int id, {
  String text = 'note',
  MessageAuthor author = MessageAuthor.me,
}) => Message(
  id: id,
  createdAt: DateTime(2026, 11, 13).add(Duration(minutes: id)),
  author: author,
  text: text,
);

class _RecordingMessages extends FakeMessageRepository {
  _RecordingMessages({super.seed, this.failAt});

  final int? failAt;
  final offsets = <int>[];

  @override
  TaskEither<AppFailure, List<Message>> latest(int limit, {int offset = 0}) {
    offsets.add(offset);
    return offset == failAt
        ? TaskEither.left(const AppFailure.database(message: 'read failed'))
        : super.latest(limit, offset: offset);
  }
}

void main() {
  final question = _note(1000, text: 'question');

  test('simple estimate rounds up and counts actual role-specific text', () {
    expect(estimateTokens(''), 0);
    expect(estimateTokens('abc'), 1);
    expect(estimateTokens('abcd'), 2);
    expect(estimateTokens('中文内容测试'), 6);
    expect(estimateTokens('abc中文😀'), 5);
    final reply = _note(
      1,
      text: 'plain assistant text',
      author: MessageAuthor.ai,
    );
    expect(estimateMessageTokens(reply), estimateTokens(reply.text) + 8);
    expect(
      estimateMessageTokens(_note(1, text: reply.text)),
      greaterThan(estimateMessageTokens(reply)),
    );
  });

  test(
    'fills exact budget and stops at the first non-fitting older note',
    () async {
      final newest = _note(3);
      final next = _note(2);
      final repo = _RecordingMessages(seed: [_note(1), next, newest, question]);
      final budget = [
        question,
        newest,
        next,
      ].fold(0, (sum, note) => sum + estimateMessageTokens(note));
      final result = await loadAgentHistory(
        messages: repo,
        question: question,
        budget: budget,
      ).run();
      expect(result.toNullable(), [question, newest, next]);
      final smaller = await loadAgentHistory(
        messages: repo,
        question: question,
        budget: budget - 1,
      ).run();
      expect(smaller.toNullable(), [question, newest]);
    },
  );

  test(
    'does not skip an oversized recent note to include older messages',
    () async {
      final repo = _RecordingMessages(
        seed: [
          _note(1),
          _note(2, text: 'x' * 600),
          question,
        ],
      );
      final result = await loadAgentHistory(
        messages: repo,
        question: question,
        budget: 100,
      ).run();
      expect(result.toNullable(), [question]);
    },
  );

  test(
    'always keeps an oversized question without reading unneeded pages',
    () async {
      final repo = _RecordingMessages(seed: [_note(1)]);
      for (final budget in [-1, 0, 1]) {
        final result = await loadAgentHistory(
          messages: repo,
          question: question,
          budget: budget,
        ).run();
        expect(result.toNullable(), [question]);
      }
      expect(repo.offsets, isEmpty);
    },
  );

  test(
    'loads multiple pages and re-running the task does not duplicate history',
    () async {
      final repo = _RecordingMessages(
        seed: [for (var id = 1; id <= 150; id++) _note(id), question],
      );
      final task = loadAgentHistory(
        messages: repo,
        question: question,
        budget: 25600,
      );
      final first = (await task.run()).toNullable();
      expect(first, hasLength(151));
      expect(first?.first, question);
      expect(first?.last.id, 1);
      expect(repo.offsets, [0, 64, 128]);
      expect((await task.run()).toNullable(), first);
    },
  );

  test(
    'handles empty history and a question not yet in the repository',
    () async {
      final empty = await loadAgentHistory(
        messages: _RecordingMessages(),
        question: question,
        budget: 1000,
      ).run();
      expect(empty.toNullable(), [question]);
      final result = await loadAgentHistory(
        messages: _RecordingMessages(seed: [_note(1), _note(1001)]),
        question: question,
        budget: 1000,
      ).run();
      expect(result.toNullable()?.map((note) => note.id), [1000, 1]);
    },
  );

  test(
    'propagates a later page failure instead of sending partial history',
    () async {
      final repo = _RecordingMessages(
        seed: [for (var id = 1; id <= 150; id++) _note(id)],
        failAt: 64,
      );
      final result = await loadAgentHistory(
        messages: repo,
        question: question,
        budget: 25600,
      ).run();
      expect(
        result.getLeft().toNullable(),
        const AppFailure.database(message: 'read failed'),
      );
    },
  );

  test(
    'selected messages retain chronological roles and include question once',
    () async {
      final result = await loadAgentHistory(
        messages: _RecordingMessages(
          seed: [
            _note(1),
            _note(2, author: MessageAuthor.ai),
            question,
          ],
        ),
        question: question,
        budget: 1000,
      ).run();
      final history = buildAgentHistory(
        result.getOrElse((failure) => throw failure),
      );
      expect(history.map((turn) => turn.role.name), [
        'user',
        'assistant',
        'user',
      ]);
      expect(history.last.text, contains('question'));
    },
  );
}
