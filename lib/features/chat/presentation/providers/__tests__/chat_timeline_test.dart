import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_timeline.dart';

Message _m(int id, DateTime at) =>
    Message(id: id, createdAt: at, author: MessageAuthor.me, text: '$id');

Message _question(int id, DateTime at) => _m(id, at).copyWith(askedAi: true);

Message _answer(int id, DateTime at) =>
    _m(id, at).copyWith(author: MessageAuthor.ai);

String _describe(ChatTimelineItem item) => switch (item) {
  TimelineMessage(:final message) => 'm${message.id}',
  TimelineAiGroup(:final messages) =>
    'ai${messages.length}:${messages.map((message) => message.id).join(',')}',
  TimelineDay(:final day) => 'd${day.month}/${day.day}',
};

void main() {
  test('projection reuses unchanged runs across insertion and deletion', () {
    final day = DateTime(2026, 11, 12);
    final messages = [_m(3, day), _answer(2, day), _question(1, day)];
    final previous = buildChatTimeline(messages);
    final cache = <int, ChatTimelineItem>{3: previous[0], 2: previous[1]};
    final inserted = buildChatTimeline([
      _m(4, day),
      ...messages,
    ], previous: cache);
    expect(inserted[1], same(previous[0]));
    expect(inserted[2], same(previous[1]));
    final deleted = buildChatTimeline([
      messages[0],
      messages[1],
    ], previous: cache);
    expect(deleted[0], same(previous[0]));
    expect(
      (deleted[1] as TimelineAiGroup).messages.map((message) => message.id),
      [2],
    );
    expect(visibleChatTimeline(inserted, aiMode: true).map(_describe), [
      'm4',
      'm3',
      'm2',
      'm1',
      'd11/12',
    ]);
    expect(visibleChatTimeline(inserted, aiMode: false), same(inserted));
  });
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

    test('combines adjacent AI exchanges and counts both authors', () {
      final day = DateTime(2026, 11, 12, 10);
      final items = buildChatTimeline([
        _answer(6, day),
        _question(5, day),
        _answer(4, day),
        _question(3, day),
        _m(2, day),
        _m(1, day),
      ]);
      expect(items.map(_describe), ['ai4:6,5,4,3', 'm2', 'm1', 'd11/12']);
      final group = items.first as TimelineAiGroup;
      expect(() => group.messages.clear(), throwsUnsupportedError);
    });

    test('keeps separate AI groups around ordinary messages', () {
      final day = DateTime(2026, 11, 12, 10);
      final items = buildChatTimeline([
        _answer(5, day),
        _question(4, day),
        _m(3, day),
        _answer(2, day),
        _question(1, day),
      ]);
      expect(items.map(_describe), ['ai2:5,4', 'm3', 'ai2:2,1', 'd11/12']);
    });

    test('counts orphan answers and a pending question', () {
      final day = DateTime(2026, 11, 12, 10);
      final items = buildChatTimeline([
        _answer(3, day),
        _answer(2, day),
        _m(1, day),
      ]);
      expect(items.map(_describe), ['ai2:3,2', 'm1', 'd11/12']);
      expect(buildChatTimeline([_question(4, day)]).map(_describe), [
        'ai1:4',
        'd11/12',
      ]);
    });

    test('splits AI runs at calendar boundaries', () {
      final items = buildChatTimeline([
        _answer(2, DateTime(2026, 11, 13, 0, 1)),
        _question(1, DateTime(2026, 11, 12, 23, 59)),
      ]);
      expect(items.map(_describe), ['ai1:2', 'd11/13', 'ai1:1', 'd11/12']);
    });
  });
}
