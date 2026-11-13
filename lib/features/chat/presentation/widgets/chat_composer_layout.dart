import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_artwork_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_artwork.dart';
import 'chat_composer_controls.dart';
import 'chat_composer_keyboard_transition.dart';

class ChatComposerLayout extends StatelessWidget {
  const ChatComposerLayout({
    required this.input,
    required this.toggle,
    required this.attachments,
    required this.onRemoveAttachment,
    required this.showWelcome,
    super.key,
  });

  final Widget input;
  final Widget toggle;
  final List<String> attachments;
  final ValueChanged<String> onRemoveAttachment;
  final bool showWelcome;

  @override
  Widget build(BuildContext context) {
    final progress = ChatComposerKeyboardTransition.progressOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final fullSize = AppArtworkTokens.welcomeSizeFor(
      width,
      keyboardOpen: false,
    );
    final compactSize = AppArtworkTokens.welcomeSizeFor(
      width,
      keyboardOpen: true,
    );
    final size = fullSize + (compactSize - fullSize) * progress;
    return Stack(
      children: [
        if (showWelcome)
          Positioned(
            top: 0,
            left: (AppSizes.minTouchTarget + AppSpacing.xs) * progress,
            right: 0,
            child: IgnorePointer(
              child: Align(
                alignment: const Alignment(
                  AppArtworkTokens.welcomeAlignment,
                  0,
                ),
                child: AppArtwork(
                  BrandArt.welcome,
                  size: size,
                  decodeSize: fullSize,
                ),
              ),
            ),
          ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: showWelcome
                  ? size * (1 - AppArtworkTokens.welcomeOverlap)
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
}
