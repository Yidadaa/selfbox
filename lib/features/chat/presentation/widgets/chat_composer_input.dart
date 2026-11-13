import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ai_composer_glow.dart';
import '../providers/composer_controller.dart';
import 'chat_composer_attachment.dart';
import 'chat_composer_input_row.dart';
import 'chat_composer_keyboard_transition.dart';
import 'chat_composer_tabs.dart';

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
    final aiMode = ref.watch(
      composerControllerProvider.select((state) => state.aiMode),
    );
    return TextFieldTapRegion(
      child: Row(
        children: [
          ChatComposerAttachment(external: true, keyboardOpen: keyboardOpen),
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
    final progress = ChatComposerKeyboardTransition.progressOf(context);
    final navigationHeight =
        (AppSizes.minTouchTarget + AppSpacing.sm) * (1 - progress);
    final verticalPadding = AppSpacing.md * (1 - progress);
    final editorMaxHeight = (maxHeight - navigationHeight - verticalPadding)
        .clamp(AppSizes.iconMd, double.infinity);
    return _ComposerGlassSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChatComposerInputRow(
            controller: controller,
            focusNode: focusNode,
            keyboardOpen: keyboardOpen,
            maxEditorHeight: editorMaxHeight,
          ),
          ChatComposerTabs(keyboardOpen: keyboardOpen, navigation: navigation),
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
