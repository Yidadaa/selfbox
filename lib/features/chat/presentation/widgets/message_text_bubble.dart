import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/message_tokens.dart';
import '../../domain/models/message.dart';
import '../../domain/services/message_links.dart';
import 'message_bookmark.dart';
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
    if (bookmark != null) return MessageBookmark(url: bookmark);
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
