import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../providers/composer_controller.dart';
import 'chat_composer_controls.dart';

class ChatComposerInput extends ConsumerWidget {
  const ChatComposerInput({
    required this.controller,
    required this.focusNode,
    required this.keyboardOpen,
    required this.maxHeight,
    this.navigation,
    super.key,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool keyboardOpen;
  final double maxHeight;
  final Widget? navigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(composerControllerProvider.notifier);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (keyboardOpen) ...[
          GlassContainer(
            quality: GlassQuality.premium,
            useOwnLayer: true,
            shape: const LiquidRoundedSuperellipse(
              borderRadius: AppRadius.pill,
            ),
            child: ChatAttachButton(onTap: notifier.pickImage),
          ),
          const Gap(AppSpacing.xs),
        ],
        Expanded(
          key: const ValueKey('chat-input'),
          child: _InputField(
            controller: controller,
            focusNode: focusNode,
            keyboardOpen: keyboardOpen,
            maxHeight: maxHeight,
            navigation: navigation,
          ),
        ),
      ],
    );
  }
}

class _InputField extends ConsumerWidget {
  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.keyboardOpen,
    required this.maxHeight,
    this.navigation,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool keyboardOpen;
  final double maxHeight;
  final Widget? navigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final glass = context.glass;
    final (aiMode, canSend) = ref.watch(
      composerControllerProvider.select((s) => (s.aiMode, s.canSend)),
    );
    final notifier = ref.read(composerControllerProvider.notifier);
    return GlassTextField(
      quality: GlassQuality.premium,
      useOwnLayer: true,
      controller: controller,
      focusNode: focusNode,
      onChanged: notifier.setText,
      minLines: 1,
      maxLines: 6,
      maxHeight: maxHeight,
      keyboardType: TextInputType.multiline,
      placeholder: aiMode ? t.chat.aiInputHint : t.chat.inputHint,
      shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.xl),
      padding: EdgeInsets.fromLTRB(
        keyboardOpen ? AppSpacing.md : AppSpacing.xxs,
        AppSpacing.xs,
        AppSpacing.xxs,
        AppSpacing.xs,
      ),
      textStyle: Theme.of(context).textTheme.bodyLarge
          ?.copyWith(color: glass.foreground),
      placeholderStyle: Theme.of(context).textTheme.bodyLarge
          ?.copyWith(color: glass.foregroundMuted),
      iconSpacing: 0,
      glowColor: aiMode ? glass.accent : null,
      prefixIcon: keyboardOpen
          ? null
          : ChatAttachButton(onTap: notifier.pickImage),
      suffixIcon: ChatSendButton(enabled: canSend, onTap: notifier.send),
      // Keep the bottom slot mounted so opening the keyboard does not
      // replace the package's internal editable subtree.
      bottom: AnimatedSize(
        duration: AppMotion.fast,
        alignment: Alignment.topCenter,
        child: keyboardOpen
            ? const SizedBox.shrink()
            : navigation ?? const SizedBox.shrink(),
      ),
    );
  }
}
