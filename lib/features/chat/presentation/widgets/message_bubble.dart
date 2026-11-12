import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_markdown_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/message_tokens.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/message.dart';
import 'date_labels.dart';
import 'message_image_stack.dart';

export '../../../../core/theme/message_tokens.dart'
    show kBubbleImageDecodeWidth;

class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    required this.message,
    required this.resolveImage,
    this.onImageTap,
    this.onLongPress,
    super.key,
  });
  final Message message;
  final File? Function(String relativePath) resolveImage;
  final ValueChanged<String>? onImageTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = message.author == MessageAuthor.me;
    final glass = context.glass;
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
            onLongPress: onLongPress,
            child: ClipPath(
              clipper: _SpeechClipper(mine),
              child: ColoredBox(
                key: const ValueKey('message-surface'),
                color: mine ? glass.bubbleMine : glass.bubbleOther,
                child: _BubbleContent(
                  message: message,
                  resolveImage: resolveImage,
                  onImageTap: onImageTap,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleContent extends ConsumerWidget {
  const _BubbleContent({
    required this.message,
    required this.resolveImage,
    this.onImageTap,
  });
  final Message message;
  final File? Function(String) resolveImage;
  final ValueChanged<String>? onImageTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = context.glass;
    final foreground = message.author == MessageAuthor.me
        ? glass.onBubbleMine
        : glass.onBubbleOther;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.images.isNotEmpty) ...[
            MessageImageStack(
              paths: message.images,
              resolveImage: resolveImage,
              onTap: () => onImageTap?.call(message.images.first),
            ),
            if (message.text.isNotEmpty) const Gap(AppSpacing.xs),
          ],
          if (message.text.isNotEmpty)
            switch (message.author) {
              MessageAuthor.me => Text(
                message.text,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: foreground),
              ),
              MessageAuthor.ai => SmoothMarkdown(
                data: message.text,
                styleSheet: AppMarkdownTheme.of(context, textColor: foreground),
              ),
            },
          const Gap(AppSpacing.xxs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.askedAi) ...[
                Icon(
                  Icons.auto_awesome,
                  size: AppSpacing.sm,
                  color: foreground,
                  semanticLabel: context.t.chat.aiMode,
                ),
                const Gap(AppSpacing.xxs),
              ],
              Text(
                formatClock(
                  message.createdAt,
                  locale: LocaleSettings.currentLocale.languageTag,
                ),
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: foreground),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One continuous outline prevents a seam between the rounded body and tail.
class _SpeechClipper extends CustomClipper<Path> {
  const _SpeechClipper(this.mine);
  final bool mine;
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
    if (mine) return path;
    return path.transform(
      (Matrix4.identity()
            ..translateByDouble(w, 0, 0, 1)
            ..scaleByDouble(-1, 1, 1, 1))
          .storage,
    );
  }

  @override
  bool shouldReclip(_SpeechClipper oldClipper) => oldClipper.mine != mine;
}
