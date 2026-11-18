import 'dart:io';

import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/message_tokens.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/message.dart';
import 'date_labels.dart';
import 'message_image_stack.dart';
import 'message_preview.dart';
import 'message_quote_link.dart';
import 'message_text_bubble.dart';

export '../../../../core/theme/message_tokens.dart'
    show kBubbleImageDecodeWidth;

class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    required this.message,
    required this.resolveImage,
    this.resolveThumbnail,
    this.onImageTap,
    this.onLongPress,
    this.onExpand,
    this.onPreviewOverflow,
    this.onQuoteTap,
    this.onDelete,
    this.selectionMode = false,
    this.selectionController,
    this.onSelectionCopy,
    this.showFooter = true,
    this.showTime = true,
    this.showSeconds = false,
    this.preview = true,
    super.key,
  });
  final Message message;
  final File? Function(String relativePath) resolveImage;
  final File? Function(String relativePath)? resolveThumbnail;
  final ValueChanged<String>? onImageTap;
  final ValueChanged<Offset>? onLongPress;
  final VoidCallback? onExpand;
  final ValueChanged<bool>? onPreviewOverflow;
  final VoidCallback? onQuoteTap;
  final VoidCallback? onDelete;
  final bool selectionMode;
  final SmoothSelectionController? selectionController;
  final VoidCallback? onSelectionCopy;
  final bool showFooter;
  final bool showTime;
  final bool showSeconds;
  final bool preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = message.author == MessageAuthor.me;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
                MediaQuery.sizeOf(context).width * MessageTokens.widthFactor,
          ),
          child: GestureDetector(
            onLongPressStart: onLongPress == null
                ? null
                : (details) => onLongPress?.call(details.globalPosition),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                MessagePreview(
                  enabled:
                      preview &&
                      message.author == MessageAuthor.ai &&
                      message.id > 0,
                  onExpand: onExpand,
                  onOverflowChanged: onPreviewOverflow,
                  reservedHeight: message.quotedMessageIds.isEmpty
                      ? 0
                      : AppSizes.minTouchTarget,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: mine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (message.images.isNotEmpty)
                        MessageImageStack(
                          paths: message.images,
                          resolveImage: resolveImage,
                          resolveThumbnail: resolveThumbnail,
                          onTap: () => onImageTap?.call(message.images.first),
                        ),
                      if (message.images.isNotEmpty && message.text.isNotEmpty)
                        const Gap(AppSpacing.xs),
                      if (message.text.isNotEmpty)
                        MessageTextBubble(
                          message: message,
                          onDelete: onDelete,
                          selectionMode: selectionMode,
                          selectionController: selectionController,
                          onSelectionCopy: onSelectionCopy,
                        ),
                    ],
                  ),
                ),
                if (message.quotedMessageIds.isNotEmpty ||
                    showFooter && (showTime || message.askedAi)) ...[
                  const Gap(AppSpacing.xxs),
                  _MessageFooter(
                    message: message,
                    showTime: showFooter && showTime,
                    showAi: showFooter && message.askedAi,
                    onQuoteTap: onQuoteTap,
                    showSeconds: showSeconds,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageFooter extends ConsumerWidget {
  const _MessageFooter({
    required this.message,
    required this.showTime,
    required this.showAi,
    required this.showSeconds,
    this.onQuoteTap,
  });
  final Message message;
  final bool showTime;
  final bool showAi;
  final bool showSeconds;
  final VoidCallback? onQuoteTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foreground = context.glass.messageMetadata;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.quotedMessageIds.isNotEmpty) ...[
            Flexible(
              child: MessageQuoteLink(
                count: message.quotedMessageIds.length,
                onTap: onQuoteTap,
              ),
            ),
            if (showAi || showTime) const Gap(AppSpacing.xs),
          ],
          if (showAi) ...[
            AppIcon(
              AppIcons.ai,
              size: AppSpacing.sm,
              color: foreground,
              semanticLabel: context.t.chat.aiMode,
            ),
            if (showTime) const Gap(AppSpacing.xxs),
          ],
          if (showTime)
            Text(
              formatClock(
                message.createdAt,
                locale: LocaleSettings.currentLocale.languageTag,
                showSeconds: showSeconds,
              ),
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: foreground),
            ),
        ],
      ),
    );
  }
}
