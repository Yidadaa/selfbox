import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_ai_tokens.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/message_tokens.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/message.dart';
import '../providers/composer_controller.dart';
import 'chat_timeline_message_row.dart';

class ChatAiGroupRow extends ConsumerWidget {
  const ChatAiGroupRow({
    required this.messages,
    required this.groupCount,
    required this.enteringIds,
    required this.onMessageEntered,
    super.key,
  });

  final List<Message> messages;
  final int groupCount;
  final Set<int> enteringIds;
  final ValueChanged<int> onMessageEntered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiMode = ref.watch(
      composerControllerProvider.select((state) => state.aiMode),
    );
    final child = aiMode
        ? Column(
            key: const ValueKey('ai-group-expanded'),
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final message in messages.reversed)
                ChatTimelineMessageRow(
                  key: ValueKey<int>(message.id),
                  message: message,
                  entering: enteringIds.contains(message.id),
                  onEntered: () => onMessageEntered(message.id),
                ),
            ],
          )
        : _HiddenAiGroup(
            key: const ValueKey('ai-group-hidden'),
            count: groupCount,
            onTap: () =>
                ref.read(composerControllerProvider.notifier).toggleAiMode(),
          );
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.bottomLeft,
        children: [
          for (final outgoing in previous)
            IgnorePointer(child: ExcludeSemantics(child: outgoing)),
          ?current,
        ],
      ),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.bottomLeft,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: child,
    );
  }
}

class _HiddenAiGroup extends StatelessWidget {
  const _HiddenAiGroup({required this.count, required this.onTap, super.key});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final label = context.t.chat.hiddenAiGroups(count: count);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Pressable(
          key: const ValueKey('hidden-ai-group'),
          onTap: onTap,
          semanticLabel: label,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.sizeOf(context).width * MessageTokens.widthFactor,
            ),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: glass.bubbleOther,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(MessageTokens.radius),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) =>
                      AppAiTokens.contentGradient(Theme.of(context).brightness)
                          .createShader(bounds),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIcon(AppIcons.ai, size: AppSizes.iconSm),
                      const Gap(AppSpacing.xs),
                      Flexible(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: glass.onBubbleOther),
                        ),
                      ),
                      const Gap(AppSpacing.xs),
                      const AppIcon(AppIcons.next, size: AppSizes.iconSm),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
