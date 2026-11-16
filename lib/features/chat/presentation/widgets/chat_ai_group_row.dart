import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_ai_tokens.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/message_tokens.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../../settings/presentation/providers/account_providers.dart';
import '../../domain/models/message.dart';
import '../providers/composer_controller.dart';

class ChatAiGroupRow extends ConsumerWidget {
  const ChatAiGroupRow({required this.messages, this.onExpand, super.key});

  final List<Message> messages;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _HiddenAiGroup(
      key: const ValueKey('ai-group-hidden'),
      count: messages.length,
      onTap:
          onExpand ??
          () => ref.read(composerControllerProvider.notifier).toggleAiMode(),
    );
  }
}

class _HiddenAiGroup extends ConsumerWidget {
  const _HiddenAiGroup({required this.count, required this.onTap, super.key});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = context.glass;
    final name =
        ref.watch(
          userProfileProvider.select(
            (value) => value.asData?.value.agentName.trim(),
          ),
        ) ??
        '';
    final label = context.t.chat.collapsedDiscussions(
      agentName: name.isEmpty ? context.t.me.agentDefaultName : name,
      count: count,
    );
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
                      const AppIcon(AppIcons.aiHidden, size: AppSizes.iconSm),
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
