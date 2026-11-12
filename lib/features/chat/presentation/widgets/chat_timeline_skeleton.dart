import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../domain/models/message.dart';
import 'message_bubble.dart';

/// Same shapes as real bubbles so nothing jumps when data arrives.
class ChatTimelineSkeleton extends StatelessWidget {
  const ChatTimelineSkeleton({required this.bottomPadding, super.key});

  final double bottomPadding;

  static final _placeholders = [
    for (final (i, text) in const [
      'Placeholder note',
      'A slightly longer placeholder note',
      'Short',
      'Another placeholder note here',
    ].indexed)
      Message(
        id: -i - 1,
        createdAt: DateTime(2026),
        author: i.isEven ? MessageAuthor.me : MessageAuthor.ai,
        text: text,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView(
        reverse: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppPageInsets.of(
            context,
            appBarHeight: AppSizes.chatHeaderHeight,
          ).top,
          AppSpacing.md,
          bottomPadding,
        ),
        children: [
          for (final message in _placeholders)
            MessageBubble(message: message, resolveImage: (_) => null),
        ],
      ),
    );
  }
}
