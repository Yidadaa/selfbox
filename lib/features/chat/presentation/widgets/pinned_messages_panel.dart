import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_relief_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/message_tokens.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/message.dart';
import '../providers/message_actions.dart';
import 'pinned_messages_list.dart';

class PinnedMessagesPanel extends ConsumerWidget {
  const PinnedMessagesPanel({
    required this.messages,
    required this.onClose,
    super.key,
  });
  final List<Message> messages;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relief = AppReliefTheme.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
        shadows: relief.surfaceShadows,
      ),
      child: GlassContainer.card(
        key: const ValueKey('pinned-panel'),
        padding: EdgeInsets.zero,
        color: MessageTokens.pinnedSurfaceColor(Theme.of(context).brightness),
        surfaceStyle: GlassSurfaceStyle.solid,
        shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
        child: DecoratedBox(
          key: const ValueKey('pinned-panel-background'),
          decoration: ShapeDecoration(
            shape: LiquidRoundedSuperellipse(
              borderRadius: AppRadius.lg,
              side: relief.border,
            ),
            gradient: MessageTokens.pinnedSurfaceGradient(
              Theme.of(context).brightness,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              messages.isEmpty
                  ? Center(
                      child: Text(
                        context.t.chat.noPins,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: context.glass.foregroundMuted),
                      ),
                    )
                  : PinnedMessagesList(messages: messages),
              Positioned(
                top: 0,
                right: 0,
                child: _PanelHeader(
                  onClear: () => _confirmClear(context, ref),
                  onClose: onClose,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    HapticFeedback.heavyImpact();
    showDialog<void>(
      context: context,
      builder: (_) => AppConfirmDialog(
        title: context.t.chat.confirmClearPins,
        secondaryLabel: context.t.common.cancel,
        primaryLabel: context.t.chat.clearPins,
        destructive: true,
        onPrimary: () async {
          if (!context.mounted) return;
          final result = await ref
              .read(messageActionsProvider.notifier)
              .clearPins();
          if (context.mounted) {
            result.match(
              (failure) => showOutcome(context, failure: failure),
              (_) {},
            );
          }
        },
      ),
    );
  }
}

class _PanelHeader extends ConsumerWidget {
  const _PanelHeader({required this.onClear, required this.onClose});
  final VoidCallback onClear;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.all(AppSpacing.xs),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _PanelButton(
          key: const ValueKey('clear-pins'),
          icon: AppIcons.delete,
          label: context.t.chat.clearPins,
          onPressed: onClear,
        ),
        const Gap(AppSpacing.xs),
        _PanelButton(
          key: const ValueKey('close-pins'),
          icon: AppIcons.close,
          label: context.t.common.close,
          onPressed: onClose,
        ),
      ],
    ),
  );
}

class _PanelButton extends ConsumerWidget {
  const _PanelButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });
  final AppIconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) => GlassIconButton(
    useOwnLayer: true,
    size: AppSizes.minTouchTarget,
    quality: GlassQuality.minimal,
    icon: AppIcon(icon, size: AppSizes.iconSm),
    semanticLabel: label,
    onPressed: onPressed,
  );
}
