import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_markdown_theme.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/message.dart';
import 'date_labels.dart';

/// Share of the row width a bubble may take; the rest keeps the timestamp
/// visible and the alignment readable.
const _maxBubbleWidthFactor = 0.74;

/// Decode near display size: full-resolution photos in a long list are the
/// fastest way to an out-of-memory kill on mid-range phones.
const kBubbleImageDecodeWidth = 720;

/// One timeline entry: notes from me on the right, AI replies on the left,
/// the time sitting beside the bubble as in the reference design.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.resolveImage,
    this.onImageTap,
    this.onLongPress,
    super.key,
  });

  final Message message;

  /// Maps a stored relative path to a file on disk.
  final File? Function(String relativePath) resolveImage;
  final ValueChanged<String>? onImageTap;
  final VoidCallback? onLongPress;

  bool get _mine => message.author == MessageAuthor.me;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * _maxBubbleWidthFactor;
    final time = Text(
      formatClock(
        message.createdAt,
        locale: LocaleSettings.currentLocale.languageTag,
      ),
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: context.glass.foregroundMuted),
    );
    final body = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        crossAxisAlignment: _mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final image in message.images) ...[
            _BubbleImage(
              file: resolveImage(image),
              onTap: onImageTap == null ? null : () => onImageTap?.call(image),
            ),
            const Gap(AppSpacing.xxs),
          ],
          if (message.text.isNotEmpty)
            _BubbleText(message: message, onLongPress: onLongPress),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        mainAxisAlignment: _mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _mine
            ? [time, const Gap(AppSpacing.xs), body]
            : [body, const Gap(AppSpacing.xs), time],
      ),
    );
  }
}

class _BubbleText extends StatelessWidget {
  const _BubbleText({required this.message, this.onLongPress});

  final Message message;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final mine = message.author == MessageAuthor.me;
    final background = mine ? glass.bubbleMine : glass.bubbleOther;
    final foreground = mine ? glass.onBubbleMine : glass.onBubbleOther;
    // The corner nearest the speaker stays tight, like a speech tail.
    const round = Radius.circular(AppRadius.md);
    const tail = Radius.circular(AppRadius.xs);

    return GestureDetector(
      onLongPress: onLongPress,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.only(
            topLeft: round,
            topRight: round,
            bottomLeft: mine ? round : tail,
            bottomRight: mine ? tail : round,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
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
        ),
      ),
    );
  }
}

class _BubbleImage extends StatelessWidget {
  const _BubbleImage({required this.file, this.onTap});

  final File? file;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final file = this.file;
    final placeholder = SizedBox.square(
      dimension: AppSizes.iconHero * 2,
      child: Icon(Icons.broken_image_outlined, color: glass.foregroundMuted),
    );
    return Pressable(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: file == null
            ? placeholder
            : Image.file(
                file,
                cacheWidth: kBubbleImageDecodeWidth,
                fit: BoxFit.cover,
                semanticLabel: context.t.chat.attachImage,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
