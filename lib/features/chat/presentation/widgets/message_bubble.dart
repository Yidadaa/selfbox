import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

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
                if (message.text.isNotEmpty) _TextBubble(message: message),
                const Gap(AppSpacing.xxs),
                _MessageFooter(message: message),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextBubble extends ConsumerWidget {
  const _TextBubble({required this.message});
  final Message message;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = context.glass;
    final mine = message.author == MessageAuthor.me;
    final foreground = mine ? glass.onBubbleMine : glass.onBubbleOther;
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: switch (message.author) {
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
        child: GlassContainer(
          key: const ValueKey('message-surface'),
          quality: GlassQuality.standard,
          shape: const LiquidRoundedSuperellipse(
            borderRadius: MessageTokens.radius,
          ),
          child: content,
        ),
      ),
    };
  }
}

class _MessageFooter extends ConsumerWidget {
  const _MessageFooter({required this.message});
  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foreground = context.glass.foregroundMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
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
