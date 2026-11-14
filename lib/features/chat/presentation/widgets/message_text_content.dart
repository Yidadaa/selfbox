import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_markdown_theme.dart';
import '../../../../core/widgets/app_markdown_builders.dart';
import '../../../../core/widgets/app_selection_popover.dart';
import '../../domain/models/message.dart';

class MessageTextContent extends HookConsumerWidget {
  const MessageTextContent({required this.message, this.onDelete, super.key});
  final Message message;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = context.glass;
    final color = message.author == MessageAuthor.me
        ? glass.onBubbleMine
        : glass.onBubbleOther;
    final compact = useMemoized(
      () =>
          message.author == MessageAuthor.ai &&
          MarkdownParser().parse(message.text).every(_intrinsicText),
      [message.author, message.text],
    );
    final content = switch (message.author) {
      MessageAuthor.me => SelectionArea(
        contextMenuBuilder: (_, state) => AppSelectionPopover(
          anchors: state.contextMenuAnchors,
          items: state.contextMenuButtonItems,
          onDelete: onDelete == null
              ? null
              : () {
                  state.clearSelection();
                  onDelete?.call();
                },
        ),
        child: Text(
          message.text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: color),
        ),
      ),
      MessageAuthor.ai => SmoothMarkdown(
        data: message.text,
        selectable: true,
        contextMenuBuilder: (_, state) => AppSelectionPopover(
          anchors: state.contextMenuAnchors,
          items: state.contextMenuButtonItems,
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
    return compact ? IntrinsicWidth(child: content) : content;
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
