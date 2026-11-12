import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../providers/composer_controller.dart';
import 'chat_composer_controls.dart';
import 'chat_composer_input.dart';

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
    final safeArea = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final reserved =
        safeArea.top +
        AppSizes.appBarHeight +
        AppSpacing.md +
        (keyboardOpen ? keyboard : safeArea.bottom) +
        (keyboardOpen ? AppSpacing.xs : AppSpacing.md) +
        AppSizes.minTouchTarget +
        AppSpacing.sm +
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ChatAiToggle(active: aiMode, onTap: notifier.toggleAiMode),
        ),
        const Gap(AppSpacing.sm),
        if (attachments.isNotEmpty) ...[
          ChatAttachmentStrip(
            paths: attachments,
            onRemove: notifier.removeAttachment,
          ),
          const Gap(AppSpacing.xs),
        ],
        ChatComposerInput(
          controller: controller,
          focusNode: focusNode,
          keyboardOpen: keyboardOpen,
          maxHeight: maxInputHeight,
          navigation: navigation,
        ),
      ],
    );
  }
}
