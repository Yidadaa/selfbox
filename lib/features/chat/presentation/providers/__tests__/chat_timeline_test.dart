import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_timeline.dart';

Message _m(int id, DateTime at) =>
    Message(id: id, createdAt: at, author: MessageAuthor.me, text: '$id');

String _describe(ChatTimelineItem item) => switch (item) {
  TimelineMessage(:final message) => 'm${message.id}',
  TimelineDay(:final day) => 'd${day.month}/${day.day}',
};

void main() {
  group('buildChatTimeline', () {
    test('is empty for no messages', () {
      expect(buildChatTimeline(const []), isEmpty);
    });

    test('puts one header after the oldest message of a single day', () {
      final items = buildChatTimeline([
        _m(2, DateTime(2026, 11, 12, 10)),
        _m(1, DateTime(2026, 11, 12, 8)),
      ]);
      expect(items.map(_describe), ['m2', 'm1', 'd11/12']);
    });

    test('inserts a header at every day boundary (newest-first)', () {
      final items = buildChatTimeline([
        _m(4, DateTime(2026, 11, 12, 9)),
        _m(3, DateTime(2026, 11, 11, 23, 59)),
        _m(2, DateTime(2026, 11, 11, 0, 1)),
        _m(1, DateTime(2026, 11, 9, 12)),
      ]);
      expect(items.map(_describe), [
        'm4',
        'd11/12',
        'm3',
        'm2',
        'd11/11',
        'm1',
        'd11/9',
      ]);
    });

    test('headers carry local midnight', () {
      final items = buildChatTimeline([_m(1, DateTime(2026, 8, 7, 9, 22))]);
      expect((items.last as TimelineDay).day, DateTime(2026, 8, 7));
    });

    test('returns an unmodifiable list', () {
      final items = buildChatTimeline([_m(1, DateTime(2026))]);
      expect(
        () => items.add(ChatTimelineItem.day(DateTime(2026))),
        throwsUnsupportedError,
      );
    });
  });
}
