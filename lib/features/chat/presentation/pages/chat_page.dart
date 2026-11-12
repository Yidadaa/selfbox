import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/router/shell_scope.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../../settings/presentation/providers/account_providers.dart';
import '../../../settings/presentation/widgets/profile_avatar.dart';
import '../../data/chat_data_providers.dart';
import '../../domain/models/message.dart';
import '../providers/assistant_controller.dart';
import '../providers/chat_feed.dart';
import '../providers/chat_timeline.dart';
import '../providers/message_actions.dart';
import '../widgets/assistant_status_bubble.dart';
import '../widgets/day_pill.dart';
import '../widgets/message_bubble.dart';
import '../widgets/welcome_timeline.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listBottom = ShellScope.bottomInsetOf(context) + AppSpacing.sm;

    return AppPageScaffold(
      title: context.t.chat.title,
      titleContent: const _ChatHeaderProfile(),
      leading: const _ChatHeaderButton(),
      actions: const [_ChatSearchButton()],
      appBarHeight: AppSizes.chatHeaderHeight,
      // The shell already accounts for the keyboard in bottomInset.
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: _ChatBody(bottomPadding: listBottom),
      ),
    );
  }
}

class _ChatHeaderProfile extends ConsumerWidget {
  const _ChatHeaderProfile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = switch (ref.watch(userProfileProvider)) {
      AsyncData(:final value) => value,
      AsyncLoading() || AsyncError() => null,
    };
    final name = profile?.nickname.trim();
    return Pressable(
      key: const ValueKey('chat-header-profile'),
      semanticLabel: context.t.me.editProfile,
      onTap: () => const ProfileRoute().push<void>(context),
      child: SizedBox(
        key: const ValueKey('chat-header-profile-layout'),
        width: 128,
        height: AppSizes.chatHeaderHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 60,
              child: GlassContainer(
                key: const ValueKey('chat-header-profile-surface'),
                quality: GlassQuality.premium,
                shape: const LiquidRoundedSuperellipse(
                  borderRadius: AppRadius.pill,
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.xxs,
                ),
                child: Center(
                  child: Text(
                    name == null || name.isEmpty
                        ? context.t.me.defaultName
                        : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              child: ProfileAvatar(
                key: const ValueKey('chat-header-avatar'),
                path: profile?.avatar,
                dimension: 56,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeaderButton extends StatelessWidget {
  const _ChatHeaderButton();

  @override
  Widget build(BuildContext context) => GlassIconButton(
    quality: GlassQuality.premium,
    icon: const Icon(Icons.settings_outlined),
    semanticLabel: context.t.chat.openSettings,
    onPressed: () => const MeRoute().go(context),
  );
}

class _ChatSearchButton extends StatelessWidget {
  const _ChatSearchButton();

  @override
  Widget build(BuildContext context) => GlassIconButton(
    quality: GlassQuality.premium,
    icon: const Icon(Icons.search_rounded),
    semanticLabel: context.t.chat.searchMessages,
    onPressed: () => const MessageSearchRoute().push<void>(context),
  );
}

class _ChatBody extends ConsumerWidget {
  const _ChatBody({required this.bottomPadding});

  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(chatFeedProvider);
    return switch (feed) {
      AsyncData(:final value) when value.items.isEmpty => WelcomeTimeline(
        bottomPadding: bottomPadding,
      ),
      AsyncData(:final value) => _Timeline(
        feed: value,
        bottomPadding: bottomPadding,
      ),
      AsyncError() => _ChatPlaceholder(
        bottomPadding: bottomPadding,
        child: EmptyState(
          icon: Icons.error_outline_rounded,
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
      AsyncLoading() => _TimelineSkeleton(bottomPadding: bottomPadding),
    };
  }
}

class _ChatPlaceholder extends ConsumerWidget {
  const _ChatPlaceholder({required this.bottomPadding, required this.child});

  final double bottomPadding;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: EdgeInsets.only(
          top:
              AppPageInsets.of(
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
          AppPageInsets.of(
            context,
            appBarHeight: AppSizes.chatHeaderHeight,
          ).top,
          AppSpacing.md,
          bottomPadding,
        ),
        itemCount: feed.items.length + lead,
        itemBuilder:
            (context, index) =>
                index < lead
                    ? AssistantStatusBubble(state: assistant)
                    : switch (feed.items[index - lead]) {
                      TimelineDay(:final day) => DayPill(day: day, now: now),
                      TimelineMessage(:final message) => MessageBubble(
                        key: ValueKey(message.id),
                        message: message,
                        resolveImage:
                            (path) => media.resolve(path).toNullable(),
                        onImageTap:
                            (path) => ImageViewerRoute(
                              path: path,
                              $extra: message.images,
                            ).push<void>(context),
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
    for (final (i, text)
        in const [
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
          AppPageInsets.of(
            context,
            appBarHeight: AppSizes.chatHeaderHeight,
          ).top,
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
