import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../data/chat_data_providers.dart';
import '../providers/composer_controller.dart';

/// Floating input pill: AI-mode toggle, multi-line text, image and send.
class ChatComposer extends HookConsumerWidget {
  const ChatComposer({super.key});

  static const _maxLines = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final glass = context.glass;
    final state = ref.watch(composerControllerProvider);
    final notifier = ref.read(composerControllerProvider.notifier);
    final controller = useTextEditingController(text: state.text);

    // The controller owns the text while typing; the provider wins when it
    // resets the draft after a successful send.
    ref.listen(composerControllerProvider.select((s) => s.text), (_, next) {
      if (controller.text != next) controller.text = next;
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.attachments.isNotEmpty) ...[
          _AttachmentStrip(
            paths: state.attachments,
            onRemove: notifier.removeAttachment,
          ),
          const Gap(AppSpacing.xs),
        ],
        GlassTextField(
          controller: controller,
          onChanged: notifier.setText,
          minLines: 1,
          maxLines: _maxLines,
          keyboardType: TextInputType.multiline,
          placeholder: state.aiMode ? t.chat.aiInputHint : t.chat.inputHint,
          shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          iconSpacing: 0,
          glowColor: state.aiMode ? glass.accent : null,
          prefixIcon: _AiToggle(
            active: state.aiMode,
            onTap: notifier.toggleAiMode,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Pressable(
                onTap: notifier.pickImage,
                semanticLabel: t.chat.attachImage,
                child: Icon(Icons.photo_outlined, color: glass.foregroundMuted),
              ),
              _SendButton(enabled: state.canSend, onTap: notifier.send),
            ],
          ),
        ),
      ],
    );
  }
}

class _AiToggle extends StatelessWidget {
  const _AiToggle({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Semantics(
      toggled: active,
      child: Pressable(
        onTap: onTap,
        semanticLabel: context.t.chat.aiMode,
        child: AnimatedSwitcher(
          duration: AppMotion.fast,
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            active ? Icons.auto_awesome : Icons.auto_awesome_outlined,
            key: ValueKey(active),
            color: active ? glass.accent : glass.foregroundMuted,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  static const _diameter = 36.0;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Pressable(
      onTap: enabled ? onTap : null,
      haptic: HapticKind.light,
      semanticLabel: context.t.chat.send,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.emphasized,
        width: _diameter,
        height: _diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? glass.accent
              : glass.foregroundMuted.withValues(alpha: 0.15),
        ),
        child: Icon(
          Icons.arrow_upward_rounded,
          size: AppSizes.iconMd,
          color: enabled ? glass.onAccent : glass.foregroundMuted,
        ),
      ),
    );
  }
}

class _AttachmentStrip extends ConsumerWidget {
  const _AttachmentStrip({required this.paths, required this.onRemove});

  final List<String> paths;
  final ValueChanged<String> onRemove;

  static const _thumb = 64.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(mediaStoreProvider);
    return SizedBox(
      height: _thumb,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, _) => const Gap(AppSpacing.xs),
        itemBuilder: (context, index) {
          final path = paths[index];
          final file = media.resolve(path).toNullable();
          return Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: file == null
                    ? const SizedBox.square(dimension: _thumb)
                    : Image.file(
                        file,
                        width: _thumb,
                        height: _thumb,
                        cacheWidth: (_thumb * 3).round(),
                        fit: BoxFit.cover,
                      ),
              ),
              Pressable(
                onTap: () => onRemove(path),
                semanticLabel: context.t.chat.removeImage,
                child: Icon(
                  Icons.cancel,
                  size: AppSizes.iconMd,
                  color: context.glass.foreground,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
