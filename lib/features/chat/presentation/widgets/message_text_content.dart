import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_markdown_theme.dart';
import '../../../../core/theme/message_tokens.dart';
import '../../../../core/widgets/app_markdown_builders.dart';
import '../../../../core/widgets/app_selection_popover.dart';
import '../../domain/models/message.dart';
import 'message_link_text.dart';
import 'open_message_link.dart';

class MessageTextContent extends HookConsumerWidget {
  const MessageTextContent({
    required this.message,
    required this.selectionMode,
    this.selectionController,
    this.onSelectionCopy,
    this.onDelete,
    this.fullWidth = false,
    super.key,
  });
  final Message message;
  final bool fullWidth;
  final VoidCallback? onDelete;
  final bool selectionMode;
  final SmoothSelectionController? selectionController;
  final VoidCallback? onSelectionCopy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = context.glass;
    final color = fullWidth
        ? glass.foreground
        : message.author == MessageAuthor.me
        ? glass.onBubbleMine
        : glass.onBubbleOther;
    final compact = useMemoized(
      () =>
          !fullWidth &&
          message.author == MessageAuthor.ai &&
          MarkdownParser().parse(message.text).every(_intrinsicText),
      [fullWidth, message.author, message.text],
    );
    final text = MessageLinkText(
      text: message.text,
      selectionMode: selectionMode,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: color),
    );
    final content = switch (message.author) {
      MessageAuthor.me =>
        selectionMode
            ? SmoothSelectionRegion(
                controller: selectionController,
                contextMenuBuilder: (_, state) => AppSelectionPopover(
                  anchors: state.contextMenuAnchors,
                  items: state.contextMenuButtonItems,
                  onCopy: onSelectionCopy,
                  onDelete: onDelete == null
                      ? null
                      : () {
                          state.clearSelection();
                          onDelete?.call();
                        },
                ),
                child: text,
              )
            : text,
      MessageAuthor.ai => SmoothMarkdown(
        data: message.text,
        onTapLink: (url) => openMessageLink(context, ref, url),
        selectable: selectionMode,
        selectionController: selectionController,
        contextMenuBuilder: (_, state) => AppSelectionPopover(
          anchors: state.contextMenuAnchors,
          items: state.contextMenuButtonItems,
          onCopy: onSelectionCopy,
          onDelete: onDelete == null
              ? null
              : () {
                  state.clearSelection();
                  onDelete?.call();
                },
        ),
        builderRegistry: appMarkdownBuilders(),
        styleSheet: AppMarkdownTheme.of(context, textColor: color),
      ),
    };
    // Markdown stretches its block column. Only text blocks support intrinsic
    // sizing; tables, code and media need their bounded viewport instead.
    return DefaultSelectionStyle(
      selectionColor: MessageTokens.selectionColor(
        Theme.of(context).brightness,
      ),
      child: compact ? IntrinsicWidth(child: content) : content,
    );
  }
}

bool _intrinsicText(MarkdownNode node) => switch (node) {
  TextNode() || InlineCodeNode() || HardBreakNode() => true,
  ParagraphNode(:final children) ||
  BoldNode(:final children) ||
  ItalicNode(:final children) ||
  StrikethroughNode(:final children) ||
  LinkNode(:final children) => children.every(_intrinsicText),
  HeaderNode(:final children) =>
    children == null || children.every(_intrinsicText),
  _ => false,
};
