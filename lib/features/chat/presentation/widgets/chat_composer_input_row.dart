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
    final (aiMode, canSend, text) = ref.watch(
      composerControllerProvider.select((s) => (s.aiMode, s.canSend, s.text)),
    );
    final notifier = ref.read(composerControllerProvider.notifier);
    final glass = context.glass;
    final t = context.t;
    final progress = ChatComposerKeyboardTransition.progressOf(context);
    // Cupertino overlays must use the alphabetic baseline reported by Text.
    final textStyle = Theme.of(context).textTheme.bodyLarge
        ?.copyWith(textBaseline: TextBaseline.alphabetic);
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => focusNode.requestFocus(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xs + AppSpacing.xs * progress,
        ),
        child: Row(
          children: [
            ChatComposerAttachment(external: false, keyboardOpen: keyboardOpen),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final placeholder = aiMode
                      ? t.chat.aiInputHint
                      : t.chat.inputHint;
                  final painter = TextPainter(
                    text: TextSpan(
                      text: text.isEmpty ? '' : text,
                      style: textStyle,
                    ),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                    maxLines: 6,
                  )..layout(maxWidth: constraints.maxWidth);
                  final multiline =
                      text.isNotEmpty &&
                      painter.computeLineMetrics().length > 1;
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: AppSizes.minTouchTarget,
                      maxHeight: maxEditorHeight,
                    ),
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
                      placeholder: placeholder,
                      style: textStyle?.copyWith(color: glass.foreground),
                      placeholderStyle: textStyle?.copyWith(
                        color: glass.foregroundMuted,
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: multiline ? AppSpacing.composerVertical : 0,
                      ),
                      decoration: null,
                    ),
                  );
                },
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
