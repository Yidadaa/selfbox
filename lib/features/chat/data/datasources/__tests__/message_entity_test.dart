import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/data/datasources/message_entity.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';

void main() {
  final at = DateTime(2026, 11, 12, 9, 30);

  group('MessageEntity mapping', () {
    test('draft -> entity -> domain keeps every field', () {
      const draft = MessageDraft(
        author: MessageAuthor.ai,
        text: '  hello  ',
        images: ['media/a.jpg', 'media/b.png'],
        askedAi: true,
      );
      final entity = draft.toEntity(at)..id = 7;
      final message = entity.toDomain();

      expect(
        message,
        Message(
          id: 7,
          createdAt: at,
          author: MessageAuthor.ai,
          text: 'hello',
          images: const ['media/a.jpg', 'media/b.png'],
          askedAi: true,
        ),
      );
    });

    test('authors round-trip through their stored index', () {
      for (final author in MessageAuthor.values) {
        final entity = MessageDraft(author: author, text: 'x').toEntity(at);
        expect(entity.toDomain().author, author);
      }
    });

    test('domain images are an unmodifiable copy of the entity list', () {
      final entity = const MessageDraft(
        author: MessageAuthor.me,
        images: ['media/a.jpg'],
      ).toEntity(at);
      final message = entity.toDomain();

      entity.images.add('media/b.jpg');
      expect(message.images, ['media/a.jpg']);
      expect(() => message.images.add('x'), throwsUnsupportedError);
    });
  });

  group('MessageDraft.isEmpty', () {
    test('whitespace-only text without images is empty', () {
      expect(
        const MessageDraft(author: MessageAuthor.me, text: ' \n ').isEmpty,
        isTrue,
      );
    });

    test('an image alone is not empty', () {
      expect(
        const MessageDraft(
          author: MessageAuthor.me,
          images: ['media/a.jpg'],
        ).isEmpty,
        isFalse,
      );
    });
  });

  group('MessageQuery.terms', () {
    test('splits on any whitespace and drops blanks', () {
      expect(const MessageQuery(keywords: '  周报 \n weekly ').terms, [
        '周报',
        'weekly',
      ]);
    });
  });
}
