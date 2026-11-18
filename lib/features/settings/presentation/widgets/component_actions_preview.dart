import 'package:gap/gap.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_action_button.dart';
import '../../../../core/widgets/app_action_popover.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_page_button.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../gen/i18n/strings.g.dart';

class ComponentActionsPreview extends StatelessWidget {
  const ComponentActionsPreview({super.key});
  @override
  Widget build(BuildContext context) => GlassGroupedSection(
    quality: AppEffects.qualityOf(context, GlassQuality.standard),
    shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
    margin: AppInsets.section,
    header: SectionHeader(context.t.me.componentLibraryButtons),
    children: [
      Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            AppActionButton(
              label: context.t.common.save,
              onPressed: () {},
              variant: AppActionButtonVariant.primary,
            ),
            const Gap(AppSpacing.xs),
            AppActionButton(label: context.t.common.cancel, onPressed: () {}),
            const Gap(AppSpacing.xs),
            AppActionButton(
              label: context.t.common.delete,
              onPressed: () {},
              variant: AppActionButtonVariant.destructive,
            ),
            const Gap(AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AppActionIconButton(
                  tooltip: context.t.common.cancel,
                  icon: AppIcons.close,
                  onPressed: () {},
                ),
                AppActionIconButton(
                  tooltip: context.t.common.save,
                  icon: AppIcons.save,
                  onPressed: () {},
                  variant: AppActionButtonVariant.primary,
                ),
                AppActionIconButton(
                  tooltip: context.t.common.delete,
                  icon: AppIcons.delete,
                  onPressed: () {},
                  variant: AppActionButtonVariant.destructive,
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

class ComponentPageActionsPreview extends StatelessWidget {
  const ComponentPageActionsPreview({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(context.t.me.componentLibraryPageButtons),
        const Gap(AppSpacing.xs),
        AppPageButton(
          label: context.t.common.retry,
          icon: AppIcons.refresh,
          onPressed: () {},
        ),
        const Gap(AppSpacing.xs),
        AppPageButton(
          label: context.t.me.clearAll,
          icon: AppIcons.delete,
          destructive: true,
          onPressed: () {},
        ),
        const Gap(AppSpacing.xs),
        AppPopoverRegion(
          actions: [
            AppPopoverAction(
              label: context.t.common.copy,
              icon: AppIcons.copy,
              onPressed: () {},
            ),
            AppPopoverAction(
              label: context.t.common.delete,
              icon: AppIcons.delete,
              destructive: true,
              onPressed: () {},
            ),
          ],
          builder: (context, open) => Pressable(
            key: const ValueKey('component-popover-preview'),
            onTap: () {
              if (context.findRenderObject() case final RenderBox box) {
                open(box.localToGlobal(box.size.center(Offset.zero)));
              }
            },
            child: Row(
              children: [
                const AppIcon(AppIcons.more),
                const Gap(AppSpacing.sm),
                Text(context.t.me.componentLibraryPopover),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
