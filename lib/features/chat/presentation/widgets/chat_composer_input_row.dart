import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../providers/composer_controller.dart';
import 'chat_composer_attachment.dart';
import 'chat_composer_controls.dart';
import 'chat_composer_editor.dart';
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
    final canSend = ref.watch(
      composerControllerProvider.select((s) => s.canSend),
    );
    final notifier = ref.read(composerControllerProvider.notifier);
    final progress = ChatComposerKeyboardTransition.progressOf(context);
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => focusNode.requestFocus(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xs,
          AppSpacing.xs * (1 - progress),
          AppSpacing.xs * (1 - progress),
          AppSpacing.xs * (1 - progress),
        ),
        child: Row(
          children: [
            ChatComposerAttachment(external: false, keyboardOpen: keyboardOpen),
            Expanded(
              child: ChatComposerEditor(
                controller: controller,
                focusNode: focusNode,
                maxHeight: maxEditorHeight,
              ),
            ),
            const Gap(AppSpacing.xs),
            ChatSendButton(enabled: canSend, onTap: notifier.send),
          ],
        ),
      ),
    );
  }
}
