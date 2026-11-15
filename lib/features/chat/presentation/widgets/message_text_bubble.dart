import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/message_tokens.dart';
import '../../domain/models/message.dart';
import '../../domain/services/message_links.dart';
import 'message_bookmark.dart';
import 'message_mine_surface.dart';
import 'message_text_content.dart';

class MessageTextBubble extends ConsumerWidget {
  const MessageTextBubble({
    required this.message,
    required this.selectionMode,
    this.selectionController,
    this.onSelectionCopy,
    this.onDelete,
    super.key,
  });
  final Message message;
  final VoidCallback? onDelete;
  final bool selectionMode;
  final SmoothSelectionController? selectionController;
  final VoidCallback? onSelectionCopy;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmark =
        message.author == MessageAuthor.me &&
            message.images.isEmpty &&
            !selectionMode
        ? singleMessageLink(message.text)
        : null;
    if (bookmark != null) {
      return MessageBookmark(url: bookmark, sourceText: message.text);
    }
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
      MessageAuthor.me => MessageMineSurface(child: content),
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
