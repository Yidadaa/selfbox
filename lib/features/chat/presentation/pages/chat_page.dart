import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/router/shell_scope.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/measure_size.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../data/chat_data_providers.dart';
import '../../domain/models/message.dart';
import '../providers/assistant_controller.dart';
import '../providers/chat_feed.dart';
import '../providers/chat_timeline.dart';
import '../providers/message_actions.dart';
import '../widgets/assistant_status_bubble.dart';
import '../widgets/chat_composer.dart';
import '../widgets/day_pill.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends HookConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composerHeight = useState(AppSizes.minTouchTarget);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    // With the keyboard up the tab bar is hidden behind it, so the composer
    // rides the keyboard instead of the bar.
    final composerBottom = keyboard > 0
        ? keyboard + AppSpacing.xs
        : ShellScope.bottomInsetOf(context);
    final listBottom = composerBottom + composerHeight.value + AppSpacing.sm;

    return AppPageScaffold(
      title: context.t.chat.title,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Positioned.fill(child: _ChatBody(bottomPadding: listBottom)),
            AnimatedPositioned(
              duration: AppMotion.fast,
              curve: AppMotion.emphasized,
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              bottom: composerBottom,
              child: MeasureSize(
                onChange: (size) => composerHeight.value = size.height,
                child: const ChatComposer(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBody extends ConsumerWidget {
  const _ChatBody({required this.bottomPadding});

  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(chatFeedProvider);
    return switch (feed) {
      AsyncData(:final value) when value.items.isEmpty => Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: EmptyState(
          icon: Icons.chat_bubble_outline_rounded,
          label: context.t.chat.empty,
        ),
      ),
      AsyncData(:final value) => _Timeline(
        feed: value,
        bottomPadding: bottomPadding,
      ),
      AsyncError() => EmptyState(
        icon: Icons.error_outline_rounded,
        label: context.t.chat.empty,
        action: GlassButton.custom(
          onTap: () => ref.invalidate(chatMessagesProvider),
          height: AppSizes.minTouchTarget,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Center(widthFactor: 1, child: Text(context.t.common.retry)),
          ),
        ),
      ),
      AsyncLoading() => _TimelineSkeleton(bottomPadding: bottomPadding),
    };
  }
}

class _Timeline extends HookConsumerWidget {
  const _Timeline({required this.feed, required this.bottomPadding});

  final ChatFeed feed;
  final double bottomPadding;

  /// Start fetching the next page this far before the oldest message.
  static const _loadMoreThreshold = 600.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final media = ref.watch(mediaStoreProvider);
    final requestedFor = useRef(-1);
    final insets = AppPageInsets.of(context);
    final assistant = ref.watch(assistantControllerProvider);
    // The reversed list's first slot is the bottom: AI status sits under the
    // newest message.
    final lead = assistant is AssistantIdle ? 0 : 1;

    bool onScroll(ScrollNotification notification) {
      final nearOldest = notification.metrics.extentAfter < _loadMoreThreshold;
      // One request per page: the item count only grows once it lands.
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
        reverse: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          insets.top,
          AppSpacing.md,
          bottomPadding,
        ),
        itemCount: feed.items.length + lead,
        itemBuilder: (context, index) => index < lead
            ? AssistantStatusBubble(state: assistant)
            : switch (feed.items[index - lead]) {
                TimelineDay(:final day) => DayPill(day: day, now: now),
                TimelineMessage(:final message) => MessageBubble(
                  key: ValueKey(message.id),
                  message: message,
                  resolveImage: (path) => media.resolve(path).toNullable(),
                  onImageTap: (path) =>
                      ImageViewerRoute(path: path).push<void>(context),
                  onLongPress: () => _showActions(context, ref, message),
                ),
              },
      ),
    );
  }

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    Message message,
  ) {
    final t = context.t;
    // The sheet dismisses itself after any action; handlers must not pop.
    return showGlassActionSheet<void>(
      context: context,
      cancelLabel: t.common.cancel,
      actions: [
        if (message.text.isNotEmpty)
          GlassActionSheetAction(
            label: t.common.copy,
            icon: const Icon(Icons.copy_rounded),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message.text));
            },
          ),
        GlassActionSheetAction(
          label: t.common.delete,
          icon: const Icon(Icons.delete_outline_rounded),
          style: GlassActionSheetStyle.destructive,
          onPressed: () {
            HapticFeedback.heavyImpact();
            ref.read(messageActionsProvider.notifier).delete(message);
          },
        ),
      ],
    );
  }
}

/// Same shapes as real bubbles so nothing jumps when data arrives.
class _TimelineSkeleton extends StatelessWidget {
  const _TimelineSkeleton({required this.bottomPadding});

  final double bottomPadding;

  static final _placeholders = [
    for (final (i, text) in const [
      'Placeholder note',
      'A slightly longer placeholder note',
      'Short',
      'Another placeholder note here',
    ].indexed)
      Message(
        id: -i - 1,
        createdAt: DateTime(2026),
        author: i.isEven ? MessageAuthor.me : MessageAuthor.ai,
        text: text,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView(
        reverse: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          bottomPadding,
        ),
        children: [
          for (final message in _placeholders)
            MessageBubble(message: message, resolveImage: (_) => null),
        ],
      ),
    );
  }
}
