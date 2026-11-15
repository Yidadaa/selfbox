import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/message_tokens.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/repositories/web_research_repository.dart';
import '../providers/message_link_preview.dart';
import 'message_mine_surface.dart';
import 'open_message_link.dart';

class MessageBookmark extends ConsumerWidget {
  const MessageBookmark({
    required this.url,
    required this.sourceText,
    super.key,
  });
  final String url;
  final String sourceText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(messageLinkPreviewProvider(url));
    final page = result.asData?.value.toNullable();
    return Pressable(
      key: const ValueKey('message-bookmark'),
      onTap: () => openMessageLink(context, ref, url),
      semanticLabel: url,
      child: RepaintBoundary(
        child: MessageMineSurface(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: page == null
                ? Text(
                    sourceText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.glass.onBubbleMine,
                      decoration: TextDecoration.underline,
                      decorationColor: context.glass.onBubbleMine,
                    ),
                  )
                : _BookmarkContent(url: url, page: page),
          ),
        ),
      ),
    );
  }
}

class _BookmarkContent extends ConsumerWidget {
  const _BookmarkContent({required this.url, required this.page});
  final String url;
  final WebPageContent? page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final host = Uri.parse(url).host;
    final title = page?.title.trim() ?? '';
    final summary = page?.description.trim() ?? '';
    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      color: context.glass.onBubbleMine,
      fontWeight: FontWeight.w600,
    );
    final summaryStyle = theme.textTheme.bodySmall?.copyWith(
      color: context.glass.onBubbleMine,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _BookmarkIcon(url: page?.iconUrl ?? ''),
            const Gap(AppSpacing.xs),
            Expanded(
              child: Text(
                host,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: summaryStyle,
              ),
            ),
          ],
        ),
        const Gap(AppSpacing.xxs),
        _BookmarkText(text: title.isEmpty ? host : title, style: titleStyle),
        const Gap(AppSpacing.xxs),
        _BookmarkText(
          text: summary.isEmpty
              ? context.t.chat.linkPreviewUnavailable
              : summary,
          style: summaryStyle,
        ),
      ],
    );
  }
}

class _BookmarkText extends ConsumerWidget {
  const _BookmarkText({required this.text, required this.style});
  final String text;
  final TextStyle? style;
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
}

class _BookmarkIcon extends ConsumerWidget {
  const _BookmarkIcon({required this.url});
  final String url;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = AppIcon(
      AppIcons.webRead,
      size: MessageTokens.bookmarkIconSize,
      color: context.glass.onBubbleMine,
    );
    return SizedBox.square(
      dimension: MessageTokens.bookmarkIconSize,
      child: url.isEmpty
          ? fallback
          : CachedNetworkImage(
              imageUrl: url,
              memCacheWidth:
                  (MessageTokens.bookmarkIconSize *
                          MediaQuery.devicePixelRatioOf(context))
                      .ceil(),
              memCacheHeight:
                  (MessageTokens.bookmarkIconSize *
                          MediaQuery.devicePixelRatioOf(context))
                      .ceil(),
              fit: BoxFit.contain,
              placeholder: (_, _) => fallback,
              errorWidget: (_, _, _) => fallback,
            ),
    );
  }
}
