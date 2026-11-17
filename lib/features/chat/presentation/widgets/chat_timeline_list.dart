import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/shell_scope.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/clock.dart';
import '../../domain/models/message.dart';
import '../providers/assistant_controller.dart';
import '../providers/chat_feed.dart';
import '../providers/chat_scroll_controller.dart';
import '../providers/chat_timeline.dart';
import '../providers/composer_controller.dart';
import 'assistant_status_bubble.dart';
import 'chat_ai_group_row.dart';
import 'chat_timeline_anchor.dart';
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
  final ChatScrollController scrollController;

  static const _loadMoreThreshold = 600.0;
  static const _statusKey = ValueKey('assistant-status');
  static const _insetKey = ValueKey('timeline-bottom-inset');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final viewportKey = useMemoized(GlobalKey.new);
    final latestKey = useMemoized(GlobalKey.new);
    final anchoring = useTimelineAnchor(
      ref,
      feed.items,
      scrollController,
      viewportKey,
      latestKey,
    );
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
      key: viewportKey,
      latestKey: latestKey,
      anchoring: anchoring,
      onExpand: (messages) {
        final index = feed.items.indexWhere(
          (item) => item is TimelineAiGroup && item.messages == messages,
        );
        if (index >= 0 && index + 1 < feed.items.length) {
          if (feed.items[index + 1] case TimelineMessage(:final message)) {
            anchoring.prefer(message.id);
          }
        }
        ref.read(composerControllerProvider.notifier).toggleAiMode();
      },
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
    required this.latestKey,
    required this.items,
    required this.lead,
    required this.childIndices,
    required this.now,
    required this.bottomPadding,
    required this.enteringIds,
    required this.onMessageEntered,
    required this.scrollController,
    required this.onScroll,
    required this.anchoring,
    required this.onExpand,
    super.key,
  });

  final List<ChatTimelineItem> items;
  final GlobalKey latestKey;
  final int lead;
  final Map<Key, int> childIndices;
  final DateTime now;
  final double? bottomPadding;
  final Set<int> enteringIds;
  final ValueChanged<int> onMessageEntered;
  final ScrollController scrollController;
  final bool Function(ScrollNotification) onScroll;
  final ({
    TimelineAnchor anchor,
    GlobalKey Function(int) keyFor,
    void Function(int) prefer,
  })
  anchoring;
  final void Function(List<Message>) onExpand;

  @override
  Widget build(BuildContext context) {
    final anchorIndex =
        childIndices[ValueKey<int>(anchoring.anchor.messageId ?? -1)];
    final pivot = anchorIndex == null ? 0 : anchorIndex + 1;
    const centerKey = ValueKey('timeline-center');
    final top =
        MediaQuery.paddingOf(context).top +
        AppSizes.chatHeaderHeight +
        AppSpacing.md;
    Widget sliver(int start, int count, {required bool newer}) => SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) =>
            _buildRow(context, newer ? start - index : start + index),
        childCount: count,
        findChildIndexCallback: (key) {
          final index = childIndices[key];
          if (index == null) return null;
          final local = newer ? start - index : index - start;
          return local >= 0 && local < count ? local : null;
        },
      ),
    );
    return NotificationListener<ScrollNotification>(
      onNotification: onScroll,
      child: CustomScrollView(
        controller: scrollController,
        reverse: true,
        center: centerKey,
        anchor: pivot == 0 ? 0 : anchoring.anchor.alignment,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          if (pivot > 0)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: sliver(pivot - 1, pivot, newer: true),
            ),
          SliverPadding(
            key: centerKey,
            padding: EdgeInsets.fromLTRB(AppSpacing.md, top, AppSpacing.md, 0),
            sliver: sliver(pivot, items.length + lead - pivot, newer: false),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, int index) {
    final row = _buildItem(context, index);
    return index == lead && items.isNotEmpty
        ? KeyedSubtree(
            key: _timelineKey(items.first),
            child: KeyedSubtree(key: latestKey, child: row),
          )
        : row;
  }

  Widget _buildItem(BuildContext context, int index) {
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
      TimelineMessage(:final message) => KeyedSubtree(
        key: ValueKey<int>(message.id),
        child: ChatTimelineMessageRow(
          key: message.askedAi || message.author == MessageAuthor.ai
              ? ValueKey(message.id)
              : anchoring.keyFor(message.id),
          message: message,
          entering: enteringIds.contains(message.id),
          onEntered: () => onMessageEntered(message.id),
        ),
      ),
      TimelineAiGroup(:final messages) => ChatAiGroupRow(
        key: ValueKey<String>('ai-group-${messages.last.id}'),
        messages: messages,
        onExpand: () => onExpand(messages),
      ),
    };
  }
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
