import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_glass_theme.dart';
import '../theme/app_spacing.dart';

/// [GlassListTile] with the app's type scale and colors applied (the glass
/// tile otherwise falls back to unthemed Cupertino text).
class AppListTile extends StatelessWidget {
  const AppListTile({
    required this.title,
    this.icon,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron,
    super.key,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;

  /// Short current value shown before the chevron, e.g. "20".
  final String? value;

  /// Replaces the value/chevron, e.g. a switch.
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Defaults to showing a chevron whenever the row is tappable.
  final bool? showChevron;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    final icon = this.icon;
    final subtitle = this.subtitle;
    final value = this.value;
    final chevron = showChevron ?? onTap != null;
    return GlassListTile(
      leading: icon == null ? null : Icon(icon, color: glass.foregroundMuted),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      titleStyle: text.bodyLarge?.copyWith(color: glass.foreground),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitleStyle: text.bodySmall?.copyWith(color: glass.foregroundMuted),
      trailing:
          trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: glass.foregroundMuted,
                    ),
                  ),
                ),
              if (value != null && chevron) const Gap(AppSpacing.xxs),
              if (chevron)
                Icon(Icons.chevron_right_rounded, color: glass.foregroundMuted),
            ],
          ),
      onTap: onTap,
    );
  }
}

/// Section header text for [GlassGroupedSection].
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelLarge
        ?.copyWith(color: context.glass.foregroundMuted),
  );
}
