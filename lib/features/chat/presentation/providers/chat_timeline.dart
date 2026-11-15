import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/models/message.dart';

part '../../../../gen/features/chat/presentation/providers/chat_timeline.freezed.dart';

@freezed
sealed class ChatTimelineItem with _$ChatTimelineItem {
  const factory ChatTimelineItem.message(Message message) = TimelineMessage;

  const factory ChatTimelineItem.aiGroup({required List<Message> messages}) =
      TimelineAiGroup;

  /// Calendar day (local midnight) that the messages after it belong to.
  const factory ChatTimelineItem.day(DateTime day) = TimelineDay;
}

DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

List<ChatTimelineItem> visibleChatTimeline(
  List<ChatTimelineItem> items, {
  required bool aiMode,
}) => aiMode
    ? List.unmodifiable([
        for (final item in items)
          if (item case TimelineAiGroup(:final messages))
            for (final message in messages) ChatTimelineItem.message(message)
          else
            item,
      ])
    : items;

/// Interleaves day headers into a newest-first message list.
///
/// The chat list is reversed (newest at the bottom), so a day's header goes
/// *after* that day's messages in this order to render above them.
List<ChatTimelineItem> buildChatTimeline(
  List<Message> newestFirst, {
  Map<int, ChatTimelineItem> previous = const {},
}) {
  final items = <ChatTimelineItem>[];
  for (var index = 0; index < newestFirst.length;) {
    final message = newestFirst[index];
    final day = _dayOf(message.createdAt.toLocal());
    if (message.askedAi || message.author == MessageAuthor.ai) {
      final start = index;
      while (index < newestFirst.length) {
        final current = newestFirst[index];
        if (_dayOf(current.createdAt.toLocal()) != day ||
            (!current.askedAi && current.author != MessageAuthor.ai)) {
          break;
        }
        index++;
      }
      final cached = previous[message.id];
      final unchanged =
          cached is TimelineAiGroup &&
          cached.messages.length == index - start &&
          cached.messages.indexed.every(
            (entry) => entry.$2 == newestFirst[start + entry.$1],
          );
      items.add(
        unchanged
            ? cached
            : ChatTimelineItem.aiGroup(
                messages: newestFirst.sublist(start, index),
              ),
      );
    } else {
      final cached = previous[message.id];
      items.add(
        cached is TimelineMessage && cached.message == message
            ? cached
            : ChatTimelineItem.message(message),
      );
      index++;
    }
    final next = index < newestFirst.length
        ? _dayOf(newestFirst[index].createdAt.toLocal())
        : null;
    if (next != day) items.add(ChatTimelineItem.day(day));
  }
  return List.unmodifiable(items);
}
