import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_artwork_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/chat_feed.dart';
import '../providers/composer_controller.dart';
import 'chat_composer_controls.dart';
import 'chat_composer_input.dart';
import 'chat_composer_layout.dart';

/// A shared input and navigation surface with a floating AI-mode toggle.
class ChatComposer extends HookConsumerWidget {
  const ChatComposer({this.navigation, this.keyboardOpen = false, super.key});

  final Widget? navigation;
  final bool keyboardOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (aiMode, attachments) = ref.watch(
      composerControllerProvider.select((s) => (s.aiMode, s.attachments)),
    );
    final notifier = ref.read(composerControllerProvider.notifier);
    final controller = useTextEditingController(
      text: ref.read(composerControllerProvider).text,
    );
    final focusNode = useFocusNode();
    useListenable(focusNode);
    final welcome = ref.watch(
      chatFeedProvider.select(
        (feed) => feed is AsyncData<ChatFeed> && feed.value.items.isEmpty,
      ),
    );
    final welcomeSize = welcome && attachments.isEmpty
        ? AppArtworkTokens.welcomeSizeFor(
            MediaQuery.sizeOf(context).width,
            keyboardOpen: keyboardOpen && focusNode.hasFocus,
          )
        : 0.0;
    final headerHeight = welcomeSize > 0
        ? welcomeSize * (1 - AppArtworkTokens.welcomeOverlap)
        : AppSizes.minTouchTarget + AppSpacing.sm;
    final safeArea = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final reserved =
        safeArea.top +
        AppSizes.appBarHeight +
        AppSpacing.md +
        (keyboardOpen ? keyboard : safeArea.bottom) +
        (keyboardOpen ? AppSpacing.xs : AppSpacing.md) +
        headerHeight +
        (attachments.isEmpty
            ? 0
            : AppSizes.attachmentThumbnail + AppSpacing.xs);
    final maxInputHeight = (MediaQuery.sizeOf(context).height - reserved).clamp(
      AppSizes.minTouchTarget + AppSpacing.md,
      double.infinity,
    );

    // The controller owns the text while typing; the provider wins when it
    // resets the draft after a successful send.
    ref.listen(composerControllerProvider.select((s) => s.text), (_, next) {
      if (controller.text != next) controller.text = next;
    });

    return ChatComposerLayout(
      toggle: ChatAiToggle(active: aiMode, onTap: notifier.toggleAiMode),
      attachments: attachments,
      onRemoveAttachment: notifier.removeAttachment,
      welcomeSize: welcomeSize,
      keyboardOpen: keyboardOpen && focusNode.hasFocus,
      input: ChatComposerInput(
        controller: controller,
        focusNode: focusNode,
        // Restore navigation on blur while the keyboard is still dismissing.
        keyboardOpen: keyboardOpen && focusNode.hasFocus,
        maxHeight: maxInputHeight,
        navigation: navigation,
      ),
    );
  }
}
