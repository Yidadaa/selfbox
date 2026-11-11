import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/models/message.dart';

part '../../../../gen/features/chat/presentation/providers/chat_timeline.freezed.dart';

@freezed
sealed class ChatTimelineItem with _$ChatTimelineItem {
  const factory ChatTimelineItem.message(Message message) = TimelineMessage;

  /// Calendar day (local midnight) that the messages after it belong to.
  const factory ChatTimelineItem.day(DateTime day) = TimelineDay;
}

DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Interleaves day headers into a newest-first message list.
///
/// The chat list is reversed (newest at the bottom), so a day's header goes
/// *after* that day's messages in this order to render above them.
List<ChatTimelineItem> buildChatTimeline(List<Message> newestFirst) {
  final items = <ChatTimelineItem>[];
  for (final (index, message) in newestFirst.indexed) {
    items.add(ChatTimelineItem.message(message));
    final day = _dayOf(message.createdAt.toLocal());
    final next = index + 1 < newestFirst.length
        ? _dayOf(newestFirst[index + 1].createdAt.toLocal())
        : null;
    if (next != day) items.add(ChatTimelineItem.day(day));
  }
  return List.unmodifiable(items);
}
