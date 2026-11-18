import 'package:gap/gap.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../theme/app_effects.dart';
import '../theme/app_glass_theme.dart';
import '../theme/app_icons.dart';
import '../theme/app_popover_tokens.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_icon.dart';

@immutable
class AppPopoverAction {
  const AppPopoverAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });
  final String label;
  final AppIconData icon;
  final VoidCallback onPressed;
  final bool destructive;
}

class AppPopoverSurface extends StatelessWidget {
  const AppPopoverSurface({
    required this.actions,
    required this.radius,
    required this.itemKeys,
    required this.highlightedIndex,
    super.key,
  });
  final List<AppPopoverAction> actions;
  final double radius;
  final List<GlobalKey> itemKeys;
  final int? highlightedIndex;

  @override
  Widget build(BuildContext context) => GlassContainer(
    key: const ValueKey('app-popover-surface'),
    quality: AppEffects.qualityOf(context, GlassQuality.standard),
    useOwnLayer: true,
    settings: LiquidGlassSettings(
      blur: context.glass.chromeBlur,
      glassColor: context.glass.chromeTint,
    ),
    shape: LiquidRoundedSuperellipse(borderRadius: radius),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: AppPopoverTokens.width,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (index, action) in actions.indexed)
                _PopoverItem(
                  action: action,
                  itemKey: itemKeys[index],
                  highlighted: highlightedIndex == index,
                  radius: AppRadius.concentric(
                    outer: radius,
                    padding: AppSpacing.xxs,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PopoverItem extends StatelessWidget {
  const _PopoverItem({
    required this.action,
    required this.itemKey,
    required this.highlighted,
    required this.radius,
  });
  final AppPopoverAction action;
  final GlobalKey itemKey;
  final bool highlighted;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = action.destructive
        ? context.glass.dialogDestructive
        : context.glass.foreground;
    return GestureDetector(
      // Claim a drag so a semantics tap cannot fire the action pressed first.
      onPanStart: (_) {},
      child: Semantics(
        key: ValueKey('popover-item-${action.label}'),
        button: true,
        label: action.label,
        onTap: action.onPressed,
        child: Container(
          key: itemKey,
          decoration: ShapeDecoration(
            color: highlighted
                ? AppPopoverTokens.highlight(Theme.of(context).brightness)
                : Colors.transparent,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          constraints: const BoxConstraints(
            minHeight: AppPopoverTokens.itemHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              AppIcon(action.icon, size: AppSizes.iconSm, color: color),
              const Gap(AppSpacing.xs),
              Expanded(
                child: Text(
                  action.label,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int? popoverActionAt(List<GlobalKey> keys, Offset position) {
  for (final (index, key) in keys.indexed) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox) continue;
    final bounds = MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
    if (bounds.contains(position)) {
      return index;
    }
  }
  return null;
}
