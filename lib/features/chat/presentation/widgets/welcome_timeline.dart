import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/message.dart';
import 'message_bubble.dart';

/// Introductory bubbles are only presentation; they never enter message history.
class WelcomeTimeline extends StatelessWidget {
  const WelcomeTimeline({required this.bottomPadding, super.key});

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final t = context.t.chat;
    final greetings = [t.welcomeFirst, t.welcomeSecond, t.welcomeThird];
    return ListView.builder(
      reverse: true,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppPageInsets.of(context, appBarHeight: AppSizes.chatHeaderHeight).top,
        AppSpacing.md,
        bottomPadding,
      ),
      itemCount: greetings.length,
      itemBuilder: (context, index) => MessageBubble(
        message: Message(
          id: -index - 1,
          createdAt: DateTime(2026),
          author: MessageAuthor.ai,
          text: greetings[greetings.length - index - 1],
        ),
        resolveImage: (_) => null,
        showFooter: false,
      ),
    );
  }
}
