import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../gen/i18n/strings.g.dart';
import '../theme/app_glass_theme.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/pressable.dart';

/// Navigation content shares its host's glass surface without nesting shaders.
class AppDockTabs extends ConsumerWidget {
  const AppDockTabs({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tabs = [
      (Icons.chat_bubble_outline_rounded, t.tabs.chat),
      (Icons.auto_awesome_outlined, t.tabs.memory),
      (Icons.person_outline_rounded, t.tabs.me),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        0,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          for (final (index, (icon, label)) in tabs.indexed)
            Expanded(
              child: _DockTab(
                icon: icon,
                label: label,
                selected: selectedIndex == index,
                onTap: () => onSelected(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _DockTab extends ConsumerWidget {
  const _DockTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = context.glass;
    final color = selected ? glass.foreground : glass.foregroundMuted;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        haptic: HapticKind.none,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppMotion.fast,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: selected ? glass.shadowBorder : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Icon(icon, color: color, size: AppSizes.iconMd),
              ),
              const Gap(AppSpacing.xxs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
