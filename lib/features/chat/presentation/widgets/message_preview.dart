import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/message_tokens.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/measure_size.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';

class MessagePreview extends HookConsumerWidget {
  const MessagePreview({
    required this.enabled,
    required this.child,
    this.onExpand,
    this.onOverflowChanged,
    this.reservedHeight = 0,
    super.key,
  });

  final bool enabled;
  final Widget child;
  final VoidCallback? onExpand;
  final ValueChanged<bool>? onOverflowChanged;
  final double reservedHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final height = useState(0.0);
    final maximum =
        (MediaQuery.sizeOf(context).height * MessageTokens.previewHeightFactor -
                reservedHeight)
            .clamp(AppSizes.minTouchTarget, double.infinity);
    final overflow = enabled && height.value > maximum;
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) onOverflowChanged?.call(overflow);
      });
      return null;
    }, [overflow]);
    if (!enabled) return child;
    final viewport = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maximum),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MessageTokens.radius),
        child: Stack(
          children: [
            SingleChildScrollView(
              key: const ValueKey('message-preview'),
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              child: MeasureSize(
                onChange: (size) {
                  if (context.mounted) {
                    height.value = size.height;
                  }
                },
                child: ExcludeSemantics(
                  excluding: overflow,
                  child: IgnorePointer(ignoring: overflow, child: child),
                ),
              ),
            ),
            if (overflow) const _PreviewOverflowHint(),
          ],
        ),
      ),
    );
    return Pressable(
      key: const ValueKey('expand-message'),
      minSize: 0,
      buttonSemantics: overflow && onExpand != null,
      semanticLabel: overflow ? context.t.chat.expandMessage : null,
      onTap: overflow ? onExpand : null,
      child: viewport,
    );
  }
}

class _PreviewOverflowHint extends ConsumerWidget {
  const _PreviewOverflowHint();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    height: MessageTokens.previewHintHeight,
    child: ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: MessageTokens.previewFade(context.glass.bubbleOther),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  context.t.chat.expandMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: MessageTokens.quoteColor(
                      Theme.of(context).brightness,
                    ),
                  ),
                ),
              ),
              const Gap(AppSpacing.xxs),
              AppIcon(
                AppIcons.next,
                size: AppSizes.iconSm,
                color: MessageTokens.quoteColor(Theme.of(context).brightness),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
