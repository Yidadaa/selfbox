import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/domain/services/agent_prompt.dart';
import 'package:selfbox/features/memory/domain/models/memory.dart';

Message _m(
  int id,
  String text, {
  MessageAuthor author = MessageAuthor.me,
  List<String> images = const [],
}) => Message(
  id: id,
  createdAt: DateTime(2026, 11, 12, 8, id),
  author: author,
  text: text,
  images: images,
);

void main() {
  group('buildAgentHistory', () {
    test('orders oldest first and stamps user notes with id and time', () {
      final history = buildAgentHistory([_m(2, 'second'), _m(1, 'first')]);
      expect(history.single.role, ModelMessageRole.user);
      expect(
        history.single.text,
        '[#1 2026-11-12 08:01] first\n\n[#2 2026-11-12 08:02] second',
      );
    });

    test('maps AI replies to assistant turns and alternates roles', () {
      final history = buildAgentHistory([
        _m(4, 'thanks'),
        _m(3, 'Sure.', author: MessageAuthor.ai),
        _m(2, 'question?'),
      ]);
      expect(history.map((m) => m.role), [
        ModelMessageRole.user,
        ModelMessageRole.assistant,
        ModelMessageRole.user,
      ]);
      expect(history[1].text, 'Sure.');
    });

    test('drops leading assistant turns so history starts with the user', () {
      final history = buildAgentHistory([
        _m(2, 'question?'),
        _m(1, 'old reply', author: MessageAuthor.ai),
      ]);
      expect(history.single.role, ModelMessageRole.user);
    });

    test('marks image attachments so the model can view them', () {
      final history = buildAgentHistory([
        _m(1, '', images: ['media/a.jpg', 'media/b.jpg']),
      ]);
      expect(history.single.text, '[#1 2026-11-12 08:01] [2 images]');
    });
  });

  group('fitHistory', () {
    test('keeps everything within budget', () {
      final notes = [_m(2, 'b'), _m(1, 'a')];
      expect(fitHistory(notes, budget: 10000, instructions: 'x'), notes);
    });

    test('drops the oldest notes first and always keeps the question', () {
      final notes = [_m(3, 'q'), _m(2, 'x' * 300), _m(1, 'y' * 300)];
      final kept = fitHistory(notes, budget: 150, instructions: '');
      expect(kept.map((m) => m.id), [3, 2]);

      final tiny = fitHistory(notes, budget: 1, instructions: 'long ' * 100);
      expect(tiny.map((m) => m.id), [3]);
    });
  });

  group('buildAgentInstructions', () {
    final entry = MemoryEntry(
      path: MemoryPath.parse('user/profile.md').getOrElse((f) => throw f),
      updatedAt: DateTime(2026),
      sizeBytes: 1,
      title: 'Profile',
    );

    test('includes the time, memory index and the diff rule', () {
      final text = buildAgentInstructions(
        now: DateTime(2026, 11, 12, 10, 5),
        memory: [entry],
        canViewImages: true,
      );
      expect(text, contains('2026-11-12 10:05'));
      expect(text, contains('- user/profile.md — Profile'));
      expect(text, contains('memory_patch'));
      expect(text, contains('view_image'));
    });

    test('says when memory is empty and hides vision without support', () {
      final text = buildAgentInstructions(
        now: DateTime(2026),
        memory: const [],
        canViewImages: false,
      );
      expect(text, contains('nothing remembered yet'));
      expect(text, isNot(contains('view_image')));
    });
  });
}
