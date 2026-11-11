import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/chat_data_providers.dart';
import '../../domain/models/message.dart';
import 'chat_timeline.dart';

part '../../../../gen/features/chat/presentation/providers/chat_feed.freezed.dart';
part '../../../../gen/features/chat/presentation/providers/chat_feed.g.dart';

/// How many of the newest messages the chat list keeps live.
@riverpod
class ChatWindow extends _$ChatWindow {
  static const pageSize = 50;

  @override
  int build() => pageSize;

  void loadMore() => state += pageSize;
}

@riverpod
Stream<List<Message>> chatMessages(Ref ref) => ref
    .watch(messageRepositoryProvider)
    .watchLatest(ref.watch(chatWindowProvider));

/// The rendered timeline plus whether older pages may exist.
@riverpod
AsyncValue<ChatFeed> chatFeed(Ref ref) => ref
    .watch(chatMessagesProvider)
    .whenData(
      (messages) => ChatFeed(
        items: buildChatTimeline(messages),
        hasMore: messages.length >= ref.watch(chatWindowProvider),
      ),
    );

@freezed
abstract class ChatFeed with _$ChatFeed {
  const factory ChatFeed({
    required List<ChatTimelineItem> items,
    required bool hasMore,
  }) = _ChatFeed;
}
