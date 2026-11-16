import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/router/shell_scope.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_artwork.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../providers/assistant_controller.dart';
import '../providers/chat_feed.dart';
import '../providers/chat_scroll_controller.dart';
import '../providers/chat_timeline.dart';
import '../providers/composer_controller.dart';
import 'chat_timeline_list.dart';
import 'chat_timeline_skeleton.dart';
import 'welcome_timeline.dart';

class ChatTimelineView extends HookConsumerWidget {
  const ChatTimelineView({this.bottomPadding, super.key});

  final double? bottomPadding;

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
      if (!ref.read(composerControllerProvider).aiMode) return;
      enteringIds.value = Set.unmodifiable({...enteringIds.value, next});
    });
    ref.listen(composerControllerProvider.select((state) => state.aiMode), (
      previous,
      next,
    ) {
      if (next) return;
      enteringIds.value = const {};
    });

    final feed = ref.watch(chatFeedProvider);
    final value = feed.value;
    if (!feed.hasError && value != null && value.items.isNotEmpty) {
      return _Timeline(
        feed: value,
        bottomPadding: bottomPadding,
        enteringIds: enteringIds.value,
        onMessageEntered: (id) => enteringIds.value = Set.unmodifiable(
          enteringIds.value.where((existing) => existing != id),
        ),
      );
    }
    return _TimelinePlaceholder(feed: feed, bottomPadding: bottomPadding);
  }
}

class _TimelinePlaceholder extends StatelessWidget {
  const _TimelinePlaceholder({required this.feed, this.bottomPadding});
  final AsyncValue<ChatFeed> feed;
  final double? bottomPadding;

  @override
  Widget build(BuildContext context) {
    final bottom =
        bottomPadding ?? ShellScope.bottomInsetOf(context) + AppSpacing.sm;
    return switch (feed) {
      AsyncData() => WelcomeTimeline(bottomPadding: bottom),
      AsyncLoading() => ChatTimelineSkeleton(bottomPadding: bottom),
      AsyncError() => _ChatPlaceholder(
        bottomPadding: bottom,
        child: EmptyState(
          illustration: BrandArt.error,
          label: context.t.common.loadFailed,
          action: Consumer(
            builder: (context, ref, _) => GlassButton.custom(
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
      ),
    };
  }
}

class _ChatPlaceholder extends StatelessWidget {
  const _ChatPlaceholder({required this.bottomPadding, required this.child});

  final double bottomPadding;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      top: AppPageInsets.of(
        context,
        appBarHeight: AppSizes.chatHeaderHeight,
      ).top,
      bottom: bottomPadding,
    ),
    child: child,
  );
}

class _Timeline extends HookConsumerWidget {
  const _Timeline({
    required this.feed,
    required this.bottomPadding,
    required this.enteringIds,
    required this.onMessageEntered,
  });

  final ChatFeed feed;
  final double? bottomPadding;
  final Set<int> enteringIds;
  final ValueChanged<int> onMessageEntered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = ref.watch(chatScrollControllerProvider);
    useOnAppLifecycleStateChange((previous, current) {
      if (current == AppLifecycleState.resumed) return;
      for (final position in scrollController.positions) {
        if (position is ScrollPositionWithSingleContext) position.goIdle();
      }
    });
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final newest = switch (feed.items.firstOrNull) {
      TimelineMessage(:final message) => message,
      TimelineAiGroup(:final messages) => messages.first,
      TimelineDay() || null => null,
    };
    final scrollTo = newest != null && enteringIds.contains(newest.id)
        ? newest.id
        : null;

    useEffect(() {
      if (scrollTo == null) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final lifecycle = WidgetsBinding.instance.lifecycleState;
        if ((lifecycle != null && lifecycle != AppLifecycleState.resumed) ||
            !scrollController.hasClients ||
            scrollController.position.extentBefore <= 0) {
          return;
        }
        if (reduceMotion) {
          scrollController.requestBottom();
          return;
        }
        if (scrollController.position.minScrollExtent < 0) {
          scrollController.requestBottom();
          return;
        }
        unawaited(
          scrollController.animateTo(
            scrollController.position.minScrollExtent,
            duration: AppMotion.messageSend,
            curve: AppMotion.messageSendCurve,
          ),
        );
      });
      return null;
    }, [scrollTo, scrollController, reduceMotion]);

    return ChatTimelineList(
      feed: feed,
      bottomPadding: bottomPadding,
      enteringIds: enteringIds,
      onMessageEntered: onMessageEntered,
      scrollController: scrollController,
    );
  }
}
