import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_ai_tokens.dart';
import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../data/chat_data_providers.dart';

class ChatAiToggle extends ConsumerWidget {
  const ChatAiToggle({required this.active, required this.onTap, super.key});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = context.glass;
    return TextFieldTapRegion(
      child: Semantics(
        toggled: active,
        child: GlassContainer(
          quality: AppEffects.qualityOf(context, GlassQuality.premium),
          useOwnLayer: true,
          shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.pill),
          child: Pressable(
            onTap: onTap,
            semanticLabel: context.t.chat.aiMode,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (active)
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => AppAiTokens.contentGradient(
                        Theme.of(context).brightness,
                      ).createShader(bounds),
                      child: AppIcon(AppIcons.ai, color: glass.foreground),
                    )
                  else
                    AppIcon(AppIcons.ai, color: glass.foregroundMuted),
                  const Gap(AppSpacing.xs),
                  ExcludeSemantics(child: _AiToggleLabel(active: active)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiToggleLabel extends StatelessWidget {
  const _AiToggleLabel({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final label = active ? context.t.chat.aiStandby : context.t.chat.aiMode;
    final text = Text(
      label,
      key: ValueKey(label),
      maxLines: 1,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: active ? context.glass.accent : context.glass.foreground,
      ),
    );
    final labelWidget = active
        ? ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) =>
                AppAiTokens.contentGradient(Theme.of(context).brightness)
                    .createShader(bounds),
            child: text,
          )
        : text;
    if (MediaQuery.disableAnimationsOf(context)) return labelWidget;
    const duration = AppMotion.aiLabelTransition;
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeInOutCubic,
      alignment: Alignment.centerRight,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.centerRight,
          children: [
            for (final child in previous)
              Positioned.fill(
                child: Align(alignment: Alignment.centerRight, child: child),
              ),
            ?current,
          ],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: AppMotion.aiLabelOffset,
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: labelWidget,
      ),
    );
  }
}

class ChatAttachButton extends ConsumerWidget {
  const ChatAttachButton({required this.onTap, super.key});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Pressable(
    onTap: onTap,
    semanticLabel: context.t.chat.attachImage,
    child: AppIcon(AppIcons.add, color: context.glass.foregroundMuted),
  );
}

class ChatSendButton extends ConsumerWidget {
  const ChatSendButton({required this.enabled, required this.onTap, super.key});

  final bool enabled;
  final VoidCallback onTap;

  static const _diameter = AppSizes.sendIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = context.glass;
    return Pressable(
      onTap: enabled ? onTap : null,
      haptic: HapticKind.light,
      semanticLabel: context.t.chat.send,
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.fast),
        curve: AppMotion.emphasized,
        width: _diameter,
        height: _diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? glass.bubbleMine : glass.shadowBorder,
        ),
        child: AppIcon(
          AppIcons.send,
          size: AppSizes.iconSm,
          color: enabled ? glass.onBubbleMine : glass.foregroundMuted,
        ),
      ),
    );
  }
}

class ChatAttachmentStrip extends ConsumerWidget {
  const ChatAttachmentStrip({
    required this.paths,
    required this.onRemove,
    super.key,
  });

  final List<String> paths;
  final ValueChanged<String> onRemove;

  static const _thumb = AppSizes.attachmentThumbnail;

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
                child: AppIcon(
                  AppIcons.dismiss,
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
