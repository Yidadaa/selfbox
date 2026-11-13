import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_artwork_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_artwork.dart';
import 'chat_composer_controls.dart';

class ChatComposerLayout extends StatelessWidget {
  const ChatComposerLayout({
    required this.input,
    required this.toggle,
    required this.attachments,
    required this.onRemoveAttachment,
    required this.welcomeSize,
    required this.keyboardOpen,
    super.key,
  });

  final Widget input;
  final Widget toggle;
  final List<String> attachments;
  final ValueChanged<String> onRemoveAttachment;
  final double welcomeSize;
  final bool keyboardOpen;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      if (welcomeSize > 0)
        Positioned(
          top: 0,
          left: keyboardOpen ? AppSizes.minTouchTarget + AppSpacing.xs : 0,
          right: 0,
          child: IgnorePointer(
            child: Align(
              alignment: const Alignment(AppArtworkTokens.welcomeAlignment, 0),
              child: AppArtwork(BrandArt.welcome, size: welcomeSize),
            ),
          ),
        ),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: welcomeSize > 0
                ? welcomeSize * (1 - AppArtworkTokens.welcomeOverlap)
                : AppSizes.minTouchTarget + AppSpacing.sm,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: toggle,
              ),
            ),
          ),
          if (attachments.isNotEmpty) ...[
            ChatAttachmentStrip(
              paths: attachments,
              onRemove: onRemoveAttachment,
            ),
            const Gap(AppSpacing.xs),
          ],
          input,
        ],
      ),
    ],
  );
}
