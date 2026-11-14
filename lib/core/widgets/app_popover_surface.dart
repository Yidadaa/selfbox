import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/app_icons.dart';
import '../theme/app_motion.dart';
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
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('app-popover-surface'),
    decoration: BoxDecoration(
      color: AppPopoverTokens.background,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [AppPopoverTokens.shadow],
    ),
    child: SizedBox(
      width: AppPopoverTokens.width,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, action) in actions.indexed)
              _PopoverItem(
                action: action,
                itemKey: itemKeys[index],
                highlighted: highlightedIndex == index,
              ),
          ],
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
  });
  final AppPopoverAction action;
  final GlobalKey itemKey;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = action.destructive
        ? AppPopoverTokens.destructive
        : AppPopoverTokens.foreground;
    return GestureDetector(
      // Claim a drag so a semantics tap cannot fire the action pressed first.
      onPanStart: (_) {},
      child: Semantics(
        key: ValueKey('popover-item-${action.label}'),
        button: true,
        label: action.label,
        onTap: action.onPressed,
        child: AnimatedContainer(
          key: itemKey,
          duration: AppMotion.duration(context, AppMotion.press),
          decoration: BoxDecoration(
            color: highlighted
                ? AppPopoverTokens.highlight
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            children: [
              AppIcon(action.icon, color: color),
              const Gap(AppSpacing.sm),
              Expanded(
                child: Text(
                  action.label,
                  style: Theme.of(context).textTheme.bodyMedium
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
    if ((box.localToGlobal(Offset.zero) & box.size).contains(position)) {
      return index;
    }
  }
  return null;
}
