import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_timeline.dart';
import 'package:selfbox/features/chat/presentation/providers/message_timestamps.dart';

Message _message(int id, DateTime time, {bool ai = false}) => Message(
  id: id,
  createdAt: time,
  author: ai ? MessageAuthor.ai : MessageAuthor.me,
  text: '$id',
);

void main() {
  test('empty timeline has no timestamps', () {
    expect(messageTimestampIds(const [], aiMode: false), isEmpty);
  });

  test('only newest in each consecutive local minute keeps its time', () {
    final times = [
      DateTime(2026, 11, 13, 10, 5, 50),
      DateTime(2026, 11, 13, 10, 5, 2),
      DateTime(2026, 11, 13, 10, 4, 59),
      DateTime(2026, 11, 13, 9, 5),
      DateTime(2026, 11, 12, 10, 5),
      DateTime(2025, 11, 12, 10, 5),
    ];
    final items = buildChatTimeline([
      for (final (index, time) in times.indexed) _message(index + 1, time),
    ]);
    expect(messageTimestampIds(items, aiMode: true), {1, 3, 4, 5, 6});
  });

  test('AI expansion groups across authors; hidden groups break adjacency', () {
    final time = DateTime(2026, 11, 13, 10, 5);
    final messages = [
      _message(4, time),
      _message(3, time, ai: true),
      _message(2, time).copyWith(askedAi: true),
      _message(1, time),
    ];
    final items = buildChatTimeline(messages);
    expect(messageTimestampIds(items, aiMode: true), {4});
    expect(messageTimestampIds(items, aiMode: false), {4, 1});
    expect(
      messageTimestampIds(buildChatTimeline(messages.sublist(1)), aiMode: true),
      {3},
    );
  });

  test(
    'new arrivals and deletion move the timestamp to the newest survivor',
    () {
      final time = DateTime(2026, 11, 13, 10, 5);
      final older = _message(1, time);
      final newer = _message(2, time.add(const Duration(seconds: 30)));
      Set<int> ids(List<Message> messages) =>
          messageTimestampIds(buildChatTimeline(messages), aiMode: false);
      expect(ids([older]), {1});
      expect(ids([newer, older]), {2});
      expect(ids([older]), {1});
    },
  );

  test('compares UTC timestamps in local calendar minutes', () {
    final time = DateTime.utc(2026, 11, 13, 23, 59, 59);
    expect(
      messageTimestampIds(
        buildChatTimeline([
          _message(2, time),
          _message(1, time.subtract(const Duration(seconds: 30))),
        ]),
        aiMode: true,
      ),
      {2},
    );
  });
}
