import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/message_share_tokens.dart';
import '../../../../core/widgets/app_artwork.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/message.dart';
import 'message_text_bubble.dart';

class MessageShareCard extends ConsumerWidget {
  const MessageShareCard({required this.message, super.key});
  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: context.glass.canvasGradient,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              const Align(
                alignment: Alignment.topCenter,
                child: AppArtwork(
                  BrandArt.welcome,
                  size: MessageShareTokens.artworkSize,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top:
                      MessageShareTokens.artworkSize -
                      MessageShareTokens.artworkOverlap,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: MessageTextBubble(
                    message: message,
                    selectionMode: false,
                  ),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.xl),
          const _ShareBrand(),
        ],
      ),
    ),
  );
}

class _ShareBrand extends ConsumerWidget {
  const _ShareBrand();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    key: const ValueKey('share-brand'),
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ClipOval(
            child: AppArtwork(
              BrandArt.avatar,
              size: MessageShareTokens.avatarSize,
            ),
          ),
          const Gap(AppSpacing.xxs),
          Text(
            context.t.app.name,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
      const Gap(AppSpacing.xxs),
      Text(
        context.t.chat.shareTagline,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: MessageShareTokens.captionSize,
          color: context.glass.foregroundMuted,
        ),
      ),
    ],
  );
}
