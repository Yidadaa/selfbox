import 'package:gap/gap.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../theme/app_glass_theme.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import 'app_icon.dart';

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
  final AppIconData? icon;
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
    final chevron = showChevron ?? onTap != null;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
      child: GlassListTile(
        // Padding belongs to the labels so a 48dp switch target does not add
        // another pair of vertical insets to an otherwise single-line row.
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        leading: icon == null
            ? null
            : AppIcon(icon, color: glass.foregroundMuted),
        title: Padding(
          padding: EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: subtitle == null ? AppSpacing.sm : 0,
          ),
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        titleStyle: text.bodyLarge?.copyWith(color: glass.foreground),
        subtitle: subtitle == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        subtitleStyle: text.bodySmall?.copyWith(color: glass.foregroundMuted),
        trailing: trailing ?? _TileValue(value: value, chevron: chevron),
        onTap: onTap,
      ),
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

class _TileValue extends StatelessWidget {
  const _TileValue({required this.value, required this.chevron});
  final String? value;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value != null)
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.listValueMaxWidth,
            ),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.glass.foregroundMuted),
            ),
          ),
        if (value != null && chevron) const Gap(AppSpacing.xxs),
        if (chevron)
          AppIcon(AppIcons.next, color: context.glass.foregroundMuted),
      ],
    );
  }
}
