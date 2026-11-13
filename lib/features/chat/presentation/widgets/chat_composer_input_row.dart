import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../providers/composer_controller.dart';
import 'chat_composer_attachment.dart';
import 'chat_composer_controls.dart';
import 'chat_composer_keyboard_transition.dart';

class ChatComposerInputRow extends ConsumerWidget {
  const ChatComposerInputRow({
    required this.controller,
    required this.focusNode,
    required this.keyboardOpen,
    required this.maxEditorHeight,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool keyboardOpen;
  final double maxEditorHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (aiMode, canSend) = ref.watch(
      composerControllerProvider.select((s) => (s.aiMode, s.canSend)),
    );
    final notifier = ref.read(composerControllerProvider.notifier);
    final glass = context.glass;
    final t = context.t;
    final progress = ChatComposerKeyboardTransition.progressOf(context);
    // Cupertino overlays must use the alphabetic baseline reported by Text.
    final textStyle = Theme.of(context).textTheme.bodyLarge
        ?.copyWith(textBaseline: TextBaseline.alphabetic);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xs + AppSpacing.xs * progress,
        AppSpacing.xs * (1 - progress),
        AppSpacing.xs * (1 - progress),
        AppSpacing.xs * (1 - progress),
      ),
      child: Row(
        children: [
          ChatComposerAttachment(external: false, keyboardOpen: keyboardOpen),
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxEditorHeight),
              child: CupertinoTextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: notifier.setText,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                minLines: 1,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.center,
                placeholder: aiMode ? t.chat.aiInputHint : t.chat.inputHint,
                style: textStyle?.copyWith(color: glass.foreground),
                placeholderStyle: textStyle?.copyWith(
                  color: glass.foregroundMuted,
                ),
                padding: EdgeInsets.zero,
                decoration: null,
              ),
            ),
          ),
          const Gap(AppSpacing.xs),
          ChatSendButton(enabled: canSend, onTap: notifier.send),
        ],
      ),
    );
  }
}
