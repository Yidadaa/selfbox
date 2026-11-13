import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ai_composer_glow.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../providers/composer_controller.dart';
import 'chat_composer_controls.dart';

const _inputShape = LiquidRoundedSuperellipse(borderRadius: AppRadius.xl);

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
    final aiMode = ref.watch(
      composerControllerProvider.select((state) => state.aiMode),
    );
    final glass = context.glass;
    return TextFieldTapRegion(
      child: Row(
        children: [
          if (keyboardOpen) ...[
            GlassContainer(
              quality: GlassQuality.standard,
              useOwnLayer: true,
              settings: LiquidGlassSettings(
                blur: glass.chromeBlur,
                glassColor: glass.chromeTint,
              ),
              shape: const LiquidRoundedSuperellipse(
                borderRadius: AppRadius.pill,
              ),
              child: ChatAttachButton(onTap: notifier.pickImage),
            ),
            const Gap(AppSpacing.xs),
          ],
          Expanded(
            key: const ValueKey('chat-input'),
            child: AiComposerGlow(
              active: aiMode,
              shape: _inputShape,
              child: _InputSurface(
                controller: controller,
                focusNode: focusNode,
                keyboardOpen: keyboardOpen,
                maxHeight: maxHeight,
                navigation: navigation,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputSurface extends StatelessWidget {
  const _InputSurface({
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
  Widget build(BuildContext context) {
    final navigationHeight = keyboardOpen
        ? 0.0
        : AppSizes.minTouchTarget + AppSpacing.sm;
    final verticalPadding = keyboardOpen ? 0.0 : AppSpacing.md;
    final editorMaxHeight = (maxHeight - navigationHeight - verticalPadding)
        .clamp(AppSizes.iconMd, double.infinity);
    return _ComposerGlassSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InputRow(
            controller: controller,
            focusNode: focusNode,
            keyboardOpen: keyboardOpen,
            maxEditorHeight: editorMaxHeight,
          ),
          AnimatedSize(
            duration: AppMotion.fast,
            alignment: Alignment.topCenter,
            child: keyboardOpen
                ? const SizedBox.shrink()
                : navigation ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ComposerGlassSurface extends ConsumerWidget {
  const _ComposerGlassSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiMode = ref.watch(
      composerControllerProvider.select((state) => state.aiMode),
    );
    final glass = context.glass;
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: aiMode ? glass.composerAiTint : glass.chromeTint),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : aiMode
          ? AppMotion.composerGlowEnter
          : AppMotion.composerGlowExit,
      curve: Curves.easeInOutCubic,
      builder: (context, tint, child) => GlassContainer(
        quality: GlassQuality.standard,
        useOwnLayer: true,
        settings: LiquidGlassSettings(
          blur: glass.chromeBlur,
          glassColor: tint ?? glass.chromeTint,
        ),
        shape: _inputShape,
        child: child,
      ),
      child: child,
    );
  }
}

class _InputRow extends ConsumerWidget {
  const _InputRow({
    required this.controller,
    required this.focusNode,
    required this.keyboardOpen,
    required this.maxEditorHeight,
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
    // Cupertino overlays must use the alphabetic baseline reported by Text.
    final textStyle = Theme.of(context).textTheme.bodyLarge
        ?.copyWith(textBaseline: TextBaseline.alphabetic);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        keyboardOpen ? AppSpacing.md : AppSpacing.xs,
        keyboardOpen ? 0.0 : AppSpacing.xs,
        keyboardOpen ? 0.0 : AppSpacing.xs,
        keyboardOpen ? 0.0 : AppSpacing.xs,
      ),
      child: Row(
        children: [
          if (!keyboardOpen) ...[
            ChatAttachButton(onTap: notifier.pickImage),
            const Gap(AppSpacing.xs),
          ],
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
