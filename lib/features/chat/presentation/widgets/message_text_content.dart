import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_markdown_theme.dart';
import '../../../../core/widgets/app_markdown_builders.dart';
import '../../../../core/widgets/app_selection_popover.dart';
import '../../domain/models/message.dart';

class MessageTextContent extends ConsumerWidget {
  const MessageTextContent({required this.message, this.onDelete, super.key});
  final Message message;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = context.glass;
    final color = message.author == MessageAuthor.me
        ? glass.onBubbleMine
        : glass.onBubbleOther;
    return switch (message.author) {
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
  }
}
