import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../providers/assistant_controller.dart';
import '../providers/chat_feed.dart';
import '../providers/chat_timeline.dart';
import '../providers/composer_controller.dart';
import 'assistant_status_bubble.dart';
import 'chat_timeline_message_row.dart';
import 'chat_timeline_skeleton.dart';
import 'day_pill.dart';
import 'welcome_timeline.dart';

class ChatTimelineView extends HookConsumerWidget {
  const ChatTimelineView({required this.bottomPadding, super.key});

  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enteringIds = useState<Set<int>>(const {});
    ref.listen(
      composerControllerProvider.select((state) => state.lastSentMessageId),
      (previous, next) {
        if (next == null || next == previous) return;
        enteringIds.value = Set.unmodifiable({...enteringIds.value, next});
      },
    );
    ref.listen(assistantReplyEventProvider, (previous, next) {
      if (next == null || next == previous) return;
      enteringIds.value = Set.unmodifiable({...enteringIds.value, next});
    });

    final feed = ref.watch(chatFeedProvider);
    return switch (feed) {
      AsyncData(:final value) when value.items.isEmpty => WelcomeTimeline(
        bottomPadding: bottomPadding,
      ),
      AsyncData(:final value) => _Timeline(
        feed: value,
        bottomPadding: bottomPadding,
        enteringIds: enteringIds.value,
        onMessageEntered: (id) => enteringIds.value = Set.unmodifiable(
          enteringIds.value.where((existing) => existing != id),
        ),
      ),
      AsyncError() => _ChatPlaceholder(
        bottomPadding: bottomPadding,
        child: EmptyState(
          label: context.t.common.loadFailed,
          action: GlassButton.custom(
            onTap: () => ref.invalidate(chatMessagesProvider),
            height: AppSizes.minTouchTarget,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Center(
                widthFactor: 1,
                child: Text(
                  context.t.common.retry,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
          ),
        ),
      ),
      AsyncLoading() => ChatTimelineSkeleton(bottomPadding: bottomPadding),
    };
  }
}

class _ChatPlaceholder extends StatelessWidget {
  const _ChatPlaceholder({required this.bottomPadding, required this.child});

  final double bottomPadding;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: EdgeInsets.only(
          top: AppPageInsets.of(
            context,
            appBarHeight: AppSizes.chatHeaderHeight,
          ).top,
          bottom: bottomPadding,
        ),
        sliver: SliverFillRemaining(hasScrollBody: false, child: child),
      ),
    ],
  );
}

Key _timelineKey(ChatTimelineItem item) => switch (item) {
  TimelineMessage(:final message) => ValueKey<int>(message.id),
  TimelineDay(:final day) => ValueKey<DateTime>(day),
};

class _Timeline extends HookWidget {
  const _Timeline({
    required this.feed,
    required this.bottomPadding,
    required this.enteringIds,
    required this.onMessageEntered,
  });

  final ChatFeed feed;
  final double bottomPadding;
  final Set<int> enteringIds;
  final ValueChanged<int> onMessageEntered;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final newest = feed.items.whereType<TimelineMessage>().firstOrNull?.message;
    final scrollTo = newest != null && enteringIds.contains(newest.id)
        ? newest.id
        : null;

    useEffect(() {
      if (scrollTo == null) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients || scrollController.offset <= 0) {
          return;
        }
        unawaited(
          scrollController.animateTo(
            0,
            duration: AppMotion.messageSend,
            curve: AppMotion.messageSendCurve,
          ),
        );
      });
      return null;
    }, [scrollTo, scrollController]);

    return _TimelineList(
      feed: feed,
      bottomPadding: bottomPadding,
      enteringIds: enteringIds,
      onMessageEntered: onMessageEntered,
      scrollController: scrollController,
    );
  }
}

class _TimelineList extends HookConsumerWidget {
  const _TimelineList({
    required this.feed,
    required this.bottomPadding,
    required this.enteringIds,
    required this.onMessageEntered,
    required this.scrollController,
  });

  final ChatFeed feed;
  final double bottomPadding;
  final Set<int> enteringIds;
  final ValueChanged<int> onMessageEntered;
  final ScrollController scrollController;

  static const _loadMoreThreshold = 600.0;
  static const _statusKey = ValueKey<String>('assistant-status');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final assistant = ref.watch(assistantControllerProvider);
    final requestedFor = useRef(-1);
    final lead = assistant is AssistantIdle ? 0 : 1;
    final childIndices = <Key, int>{
      for (final (index, item) in feed.items.indexed)
        _timelineKey(item): index + lead,
    };

    bool onScroll(ScrollNotification notification) {
      final nearOldest = notification.metrics.extentAfter < _loadMoreThreshold;
      if (nearOldest &&
          feed.hasMore &&
          requestedFor.value != feed.items.length) {
        requestedFor.value = feed.items.length;
        ref.read(chatWindowProvider.notifier).loadMore();
      }
      return false;
    }

    return NotificationListener<ScrollNotification>(
      onNotification: onScroll,
      child: ListView.builder(
        controller: scrollController,
        reverse: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppPageInsets.of(
            context,
            appBarHeight: AppSizes.chatHeaderHeight,
          ).top,
          AppSpacing.md,
          bottomPadding,
        ),
        itemCount: feed.items.length + lead,
        findChildIndexCallback: (key) =>
            key == _statusKey ? (lead == 1 ? 0 : null) : childIndices[key],
        itemBuilder: (context, index) => index < lead
            ? AssistantStatusBubble(key: _statusKey, state: assistant)
            : switch (feed.items[index - lead]) {
                TimelineDay(:final day) => DayPill(
                  key: ValueKey<DateTime>(day),
                  day: day,
                  now: now,
                ),
                TimelineMessage(:final message) => ChatTimelineMessageRow(
                  key: ValueKey<int>(message.id),
                  message: message,
                  entering: enteringIds.contains(message.id),
                  onEntered: () => onMessageEntered(message.id),
                ),
              },
      ),
    );
  }
}
