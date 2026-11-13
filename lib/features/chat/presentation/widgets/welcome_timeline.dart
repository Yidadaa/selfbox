import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_artwork_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_artwork.dart';
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
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppPageInsets.of(context, appBarHeight: AppSizes.chatHeaderHeight).top,
        AppSpacing.md,
        bottomPadding,
      ),
      children: [
        const Center(
          child: AppArtwork(BrandArt.welcome, size: AppArtworkTokens.welcome),
        ),
        const Gap(AppSpacing.lg),
        for (final (index, greeting) in greetings.indexed)
          MessageBubble(
            message: Message(
              id: -index - 1,
              createdAt: DateTime(2026),
              author: MessageAuthor.ai,
              text: greeting,
            ),
            resolveImage: (_) => null,
            showFooter: false,
          ),
      ],
    );
  }
}
