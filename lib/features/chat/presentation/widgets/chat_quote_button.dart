import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../providers/chat_feed.dart';
import '../providers/chat_scroll_controller.dart';
import '../providers/composer_controller.dart';
import 'message_quote_sheet.dart';

class ChatTimelineAction extends HookConsumerWidget {
  const ChatTimelineAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scroll = ref.watch(chatScrollControllerProvider);
    final awayFromBottom = useListenableSelector(
      scroll,
      () => scroll.hasClients && scroll.offset > AppSpacing.xl,
    );
    final hasMessages = ref.watch(
      chatFeedProvider.select((feed) => feed.value?.items.isNotEmpty ?? false),
    );
    final count = ref.watch(
      composerControllerProvider.select(
        (state) => state.quotedMessageIds.length,
      ),
    );
    if (hasMessages && awayFromBottom) {
      return ChatScrollToBottomButton(
        onTap: () {
          if (!scroll.hasClients) return;
          if (MediaQuery.disableAnimationsOf(context)) {
            scroll.jumpTo(0);
            return;
          }
          scroll.animateTo(
            0,
            duration: AppMotion.messageSend,
            curve: AppMotion.messageSendCurve,
          );
        },
      );
    }
    return count == 0 ? const SizedBox.shrink() : ChatQuoteButton(count: count);
  }
}

class ChatQuoteButton extends ConsumerWidget {
  const ChatQuoteButton({required this.count, super.key});
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _ChatFloatingButton(
    actionKey: const ValueKey('composer-quotes'),
    label: context.t.chat.quoteCount(count: count),
    icon: AppIcons.quote,
    onTap: () => showQuoteEditor(context),
  );
}

class ChatScrollToBottomButton extends ConsumerWidget {
  const ChatScrollToBottomButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextFieldTapRegion(
    child: GlassContainer(
      quality: AppEffects.qualityOf(context, GlassQuality.premium),
      useOwnLayer: true,
      shape: const LiquidOval(),
      child: SizedBox.square(
        dimension: AppSizes.minTouchTarget,
        child: Pressable(
          key: const ValueKey('chat-scroll-to-bottom'),
          semanticLabel: context.t.chat.scrollToBottom,
          onTap: onTap,
          child: AppIcon(
            AppIcons.expanded,
            size: AppSizes.iconSm,
            color: context.glass.foregroundMuted,
          ),
        ),
      ),
    ),
  );
}

class _ChatFloatingButton extends ConsumerWidget {
  const _ChatFloatingButton({
    required this.actionKey,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final Key actionKey;
  final String label;
  final AppIconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextFieldTapRegion(
    child: GlassContainer(
      quality: AppEffects.qualityOf(context, GlassQuality.standard),
      useOwnLayer: true,
      shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.pill),
      child: Pressable(
        key: actionKey,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                icon,
                size: AppSizes.iconSm,
                color: context.glass.foregroundMuted,
              ),
              const Gap(AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
