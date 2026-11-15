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
AsyncValue<ChatFeed> chatFeed(Ref ref) {
  final projection = ref.watch(chatTimelineProjectionProvider);
  return ref
      .watch(chatMessagesProvider)
      .when(
        skipLoadingOnReload: true,
        data: (messages) => AsyncData(
          ChatFeed(
            items: projection.project(messages),
            hasMore: messages.length >= ref.watch(chatWindowProvider),
          ),
        ),
        error: AsyncError.new,
        loading: () => const AsyncLoading(),
      );
}

@riverpod
ChatTimelineProjection chatTimelineProjection(Ref ref) =>
    ChatTimelineProjection();

class ChatTimelineProjection {
  Map<int, ChatTimelineItem> _previous = {};

  List<ChatTimelineItem> project(List<Message> messages) {
    final items = buildChatTimeline(messages, previous: _previous);
    _previous = {
      for (final item in items)
        if (item case TimelineMessage(:final message))
          message.id: item
        else if (item case TimelineAiGroup(:final messages))
          messages.first.id: item,
    };
    return items;
  }
}

@freezed
abstract class ChatFeed with _$ChatFeed {
  const factory ChatFeed({
    required List<ChatTimelineItem> items,
    required bool hasMore,
  }) = _ChatFeed;
}
