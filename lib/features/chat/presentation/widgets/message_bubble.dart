import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/message_tokens.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/message.dart';
import 'date_labels.dart';
import 'message_image_stack.dart';
import 'message_text_content.dart';

export '../../../../core/theme/message_tokens.dart'
    show kBubbleImageDecodeWidth;

class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    required this.message,
    required this.resolveImage,
    this.onImageTap,
    this.onLongPress,
    this.onDelete,
    this.selectionMode = false,
    this.selectionController,
    this.onSelectionCopy,
    this.showFooter = true,
    this.showTime = true,
    this.showSeconds = false,
    super.key,
  });
  final Message message;
  final File? Function(String relativePath) resolveImage;
  final ValueChanged<String>? onImageTap;
  final ValueChanged<Offset>? onLongPress;
  final VoidCallback? onDelete;
  final bool selectionMode;
  final SmoothSelectionController? selectionController;
  final VoidCallback? onSelectionCopy;
  final bool showFooter;
  final bool showTime;
  final bool showSeconds;

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
                if (message.images.isNotEmpty)
                  MessageImageStack(
                    paths: message.images,
                    resolveImage: resolveImage,
                    onTap: () => onImageTap?.call(message.images.first),
                  ),
                if (message.images.isNotEmpty && message.text.isNotEmpty)
                  const Gap(AppSpacing.xs),
                if (message.text.isNotEmpty)
                  _TextBubble(
                    message: message,
                    onDelete: onDelete,
                    selectionMode: selectionMode,
                    selectionController: selectionController,
                    onSelectionCopy: onSelectionCopy,
                  ),
                if (showFooter && (showTime || message.askedAi)) ...[
                  const Gap(AppSpacing.xxs),
                  _MessageFooter(
                    message: message,
                    showTime: showTime,
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

class _TextBubble extends ConsumerWidget {
  const _TextBubble({
    required this.message,
    required this.selectionMode,
    this.selectionController,
    this.onSelectionCopy,
    this.onDelete,
  });
  final Message message;
  final VoidCallback? onDelete;
  final bool selectionMode;
  final SmoothSelectionController? selectionController;
  final VoidCallback? onSelectionCopy;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = context.glass;
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: MessageTextContent(
        message: message,
        onDelete: onDelete,
        selectionMode: selectionMode,
        selectionController: selectionController,
        onSelectionCopy: onSelectionCopy,
      ),
    );
    return switch (message.author) {
      MessageAuthor.me => ClipPath(
        clipper: const _SpeechClipper(),
        child: ColoredBox(
          key: const ValueKey('message-surface'),
          color: glass.bubbleMine,
          child: content,
        ),
      ),
      MessageAuthor.ai => RepaintBoundary(
        child: DecoratedBox(
          key: const ValueKey('message-surface'),
          decoration: ShapeDecoration(
            color: glass.bubbleOther,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(MessageTokens.radius),
            ),
          ),
          child: content,
        ),
      ),
    };
  }
}

class _MessageFooter extends ConsumerWidget {
  const _MessageFooter({
    required this.message,
    required this.showTime,
    required this.showSeconds,
  });
  final Message message;
  final bool showTime;
  final bool showSeconds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foreground = context.glass.messageMetadata;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.askedAi) ...[
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

/// One continuous outline prevents a seam between the rounded body and tail.
class _SpeechClipper extends CustomClipper<Path> {
  const _SpeechClipper();
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final r = MessageTokens.radius.clamp(0.0, size.shortestSide / 2);
    const tail = MessageTokens.tail;
    final path = Path()
      ..moveTo(r, 0)
      ..lineTo(w - r - tail, 0)
      ..quadraticBezierTo(w - tail, 0, w - tail, r)
      ..lineTo(w - tail, h - r)
      ..quadraticBezierTo(w - tail, h - tail, w, h)
      ..quadraticBezierTo(w - tail, h, w - tail * 2, h - tail)
      ..quadraticBezierTo(w - r, h, w - r - tail, h)
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_SpeechClipper oldClipper) => false;
}
