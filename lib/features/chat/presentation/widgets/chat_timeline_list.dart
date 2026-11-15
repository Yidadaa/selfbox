import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/shell_scope.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/clock.dart';
import '../providers/assistant_controller.dart';
import '../providers/chat_feed.dart';
import '../providers/chat_timeline.dart';
import '../providers/composer_controller.dart';
import 'assistant_status_bubble.dart';
import 'chat_ai_group_row.dart';
import 'chat_timeline_message_row.dart';
import 'day_pill.dart';

Key _timelineKey(ChatTimelineItem item) => switch (item) {
  TimelineMessage(:final message) => ValueKey<int>(message.id),
  TimelineAiGroup(:final messages) => ValueKey<String>(
    'ai-group-${messages.last.id}',
  ),
  TimelineDay(:final day) => ValueKey<DateTime>(day),
};

class ChatTimelineList extends HookConsumerWidget {
  const ChatTimelineList({
    required this.feed,
    required this.bottomPadding,
    required this.enteringIds,
    required this.onMessageEntered,
    required this.scrollController,
    super.key,
  });

  final ChatFeed feed;
  final double? bottomPadding;
  final Set<int> enteringIds;
  final ValueChanged<int> onMessageEntered;
  final ScrollController scrollController;

  static const _loadMoreThreshold = 600.0;
  static const _statusKey = ValueKey('assistant-status');
  static const _insetKey = ValueKey('timeline-bottom-inset');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final aiMode = ref.watch(
      composerControllerProvider.select((state) => state.aiMode),
    );
    final hasStatus =
        aiMode &&
        ref.watch(
          assistantControllerProvider.select(
            (state) => state is! AssistantIdle,
          ),
        );
    final lead = hasStatus ? 2 : 1;
    final items = useMemoized(
      () => visibleChatTimeline(feed.items, aiMode: aiMode),
      [feed.items, aiMode],
    );
    final childIndices = useMemoized(
      () => <Key, int>{
        _insetKey: 0,
        if (hasStatus) _statusKey: 1,
        for (final (index, item) in items.indexed)
          _timelineKey(item): index + lead,
      },
      [items, lead],
    );
    final requestedFor = useRef(-1);

    bool onScroll(ScrollNotification notification) {
      final nearOldest = notification.metrics.extentAfter < _loadMoreThreshold;
      final window = ref.read(chatWindowProvider);
      if (nearOldest &&
          feed.hasMore &&
          !ref.read(chatMessagesProvider).isLoading &&
          requestedFor.value != window) {
        requestedFor.value = window;
        ref.read(chatWindowProvider.notifier).loadMore();
      }
      return false;
    }

    return _TimelineViewport(
      items: items,
      lead: lead,
      childIndices: childIndices,
      now: now,
      bottomPadding: bottomPadding,
      enteringIds: enteringIds,
      onMessageEntered: onMessageEntered,
      scrollController: scrollController,
      onScroll: onScroll,
    );
  }
}

class _TimelineViewport extends StatelessWidget {
  const _TimelineViewport({
    required this.items,
    required this.lead,
    required this.childIndices,
    required this.now,
    required this.bottomPadding,
    required this.enteringIds,
    required this.onMessageEntered,
    required this.scrollController,
    required this.onScroll,
  });

  final List<ChatTimelineItem> items;
  final int lead;
  final Map<Key, int> childIndices;
  final DateTime now;
  final double? bottomPadding;
  final Set<int> enteringIds;
  final ValueChanged<int> onMessageEntered;
  final ScrollController scrollController;
  final bool Function(ScrollNotification) onScroll;

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: onScroll,
        child: ListView.builder(
          controller: scrollController,
          reverse: true,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            MediaQuery.paddingOf(context).top +
                AppSizes.chatHeaderHeight +
                AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          itemCount: items.length + lead,
          findChildIndexCallback: (key) => childIndices[key],
          itemBuilder: (context, index) {
            if (index == 0) {
              return _BottomInset(
                key: ChatTimelineList._insetKey,
                padding: bottomPadding,
              );
            }
            if (index < lead) {
              return const _AssistantStatus(key: ChatTimelineList._statusKey);
            }
            return switch (items[index - lead]) {
              TimelineDay(:final day) => DayPill(
                key: _timelineKey(items[index - lead]),
                day: day,
                now: now,
              ),
              TimelineMessage(:final message) => ChatTimelineMessageRow(
                key: ValueKey<int>(message.id),
                message: message,
                entering: enteringIds.contains(message.id),
                onEntered: () => onMessageEntered(message.id),
              ),
              TimelineAiGroup(:final messages) => ChatAiGroupRow(
                key: ValueKey<String>('ai-group-${messages.last.id}'),
                messages: messages,
              ),
            };
          },
        ),
      );
}

class _BottomInset extends StatelessWidget {
  const _BottomInset({required this.padding, super.key});
  final double? padding;

  @override
  Widget build(BuildContext context) =>
      Gap(padding ?? ShellScope.bottomInsetOf(context) + AppSpacing.sm);
}

class _AssistantStatus extends ConsumerWidget {
  const _AssistantStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      AssistantStatusBubble(state: ref.watch(assistantControllerProvider));
}
