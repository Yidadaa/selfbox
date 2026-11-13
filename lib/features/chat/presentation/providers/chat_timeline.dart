import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/models/message.dart';

part '../../../../gen/features/chat/presentation/providers/chat_timeline.freezed.dart';

@freezed
sealed class ChatTimelineItem with _$ChatTimelineItem {
  const factory ChatTimelineItem.message(Message message) = TimelineMessage;

  const factory ChatTimelineItem.aiGroup({
    required List<Message> messages,
    required int groupCount,
  }) = TimelineAiGroup;

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
  for (var index = 0; index < newestFirst.length;) {
    final message = newestFirst[index];
    final day = _dayOf(message.createdAt.toLocal());
    if (message.askedAi || message.author == MessageAuthor.ai) {
      final messages = <Message>[];
      var questions = 0;
      var answers = 0;
      while (index < newestFirst.length) {
        final current = newestFirst[index];
        if (_dayOf(current.createdAt.toLocal()) != day ||
            (!current.askedAi && current.author != MessageAuthor.ai)) {
          break;
        }
        messages.add(current);
        if (current.askedAi) questions++;
        if (current.author == MessageAuthor.ai) answers++;
        index++;
      }
      items.add(
        ChatTimelineItem.aiGroup(
          messages: messages,
          groupCount: questions == 0 ? answers : questions,
        ),
      );
    } else {
      items.add(ChatTimelineItem.message(message));
      index++;
    }
    final next = index < newestFirst.length
        ? _dayOf(newestFirst[index].createdAt.toLocal())
        : null;
    if (next != day) items.add(ChatTimelineItem.day(day));
  }
  return List.unmodifiable(items);
}
