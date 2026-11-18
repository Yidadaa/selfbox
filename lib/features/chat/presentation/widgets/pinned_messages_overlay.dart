import 'dart:math' as math;

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/router/shell_scope.dart';
import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../providers/pinned_messages.dart';
import 'pinned_messages_panel.dart';

/// A local stack, without a modal barrier or full-screen gesture recognizer.
class PinnedMessagesOverlay extends HookConsumerWidget {
  const PinnedMessagesOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(pinnedMessagesProvider).value ?? const [];
    final expanded = useState(false);
    ref.listen(pinnedMessagesProvider, (_, next) {
      if (next.asData?.value.isEmpty ?? false) expanded.value = false;
    });
    final panel = useMemoized(
      () => RepaintBoundary(
        child: TextFieldTapRegion(
          child: PinnedMessagesPanel(
            messages: messages,
            onClose: () => expanded.value = false,
          ),
        ),
      ),
      [messages],
    );
    final top = AppPageInsets.of(
      context,
      appBarHeight: AppSizes.chatHeaderHeight,
    ).top;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final bottom = ShellScope.bottomInsetOf(context) + AppSpacing.md;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = math.max(0.0, constraints.maxHeight - top - bottom);
        final height = keyboard > 0
            ? available
            : math.min(available, MediaQuery.sizeOf(context).height / 2);
        return Stack(
          children: [
            if (messages.isNotEmpty && !expanded.value)
              Positioned(
                top: top,
                left: AppSpacing.md,
                child: _PinBubble(
                  count: messages.length,
                  onTap: () => expanded.value = true,
                ),
              ),
            if (messages.isNotEmpty && expanded.value)
              Positioned(
                top: top,
                left: AppSpacing.md,
                right: AppSpacing.md,
                height: height,
                child: panel,
              ),
          ],
        );
      },
    );
  }
}

class _PinBubble extends ConsumerWidget {
  const _PinBubble({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextFieldTapRegion(
    child: GlassContainer(
      key: const ValueKey('pinned-bubble'),
      quality: AppEffects.qualityOf(context, GlassQuality.premium),
      useOwnLayer: true,
      shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.pill),
      child: Pressable(
        semanticLabel: context.t.chat.pinnedCount(count: count),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                AppIcons.pin,
                size: AppSizes.iconSm,
                color: context.glass.foregroundMuted,
              ),
              const Gap(AppSpacing.xs),
              Text(
                context.t.chat.pinnedCount(count: count),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
