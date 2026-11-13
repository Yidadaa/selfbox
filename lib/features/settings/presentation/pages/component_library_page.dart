import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_action_button.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../widgets/settings_back_button.dart';

class ComponentLibraryPage extends StatelessWidget {
  const ComponentLibraryPage({super.key});

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: context.t.me.componentLibrary,
    leading: const SettingsBackButton(),
    body: ListView(
      padding: AppPageInsets.of(context),
      children: [
        Text(
          context.t.me.componentLibraryDescription,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: context.glass.foregroundMuted),
        ),
        const Gap(AppSpacing.md),
        GlassGroupedSection(
          quality: GlassQuality.standard,
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
                  AppActionButton(
                    label: context.t.common.cancel,
                    onPressed: () {},
                  ),
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
                        icon: Icons.close_rounded,
                        onPressed: () {},
                      ),
                      AppActionIconButton(
                        tooltip: context.t.common.save,
                        icon: Icons.save_outlined,
                        onPressed: () {},
                        variant: AppActionButtonVariant.primary,
                      ),
                      AppActionIconButton(
                        tooltip: context.t.common.delete,
                        icon: Icons.delete_outline_rounded,
                        onPressed: () {},
                        variant: AppActionButtonVariant.destructive,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        GlassGroupedSection(
          quality: GlassQuality.standard,
          shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
          margin: AppInsets.section,
          children: [
            AppListTile(
              icon: Icons.tune_rounded,
              title: context.t.me.componentLibraryDialog,
              onTap: () => _showDialogPreview(context),
            ),
            AppListTile(
              icon: Icons.warning_amber_rounded,
              title: context.t.me.componentLibraryConfirmDialog,
              onTap: () => _showConfirmDialog(context),
            ),
            AppListTile(
              icon: Icons.checklist_rounded,
              title: context.t.me.componentLibraryTile,
              subtitle: context.t.me.componentLibraryDescription,
            ),
          ],
        ),
        const Gap(AppSpacing.md),
        SectionHeader(context.t.me.componentLibraryEmptyState),
        const Gap(AppSpacing.xs),
        EmptyState(label: context.t.common.notSet),
      ],
    ),
  );

  static Future<void> _showDialogPreview(BuildContext context) =>
      showDialog<void>(
        context: context,
        builder: (_) => AppActionDialog(
          title: context.t.me.componentLibraryDialog,
          cancelLabel: context.t.common.cancel,
          actions: [
            AppDialogAction(label: context.t.common.save, onPressed: () {}),
            AppDialogAction(
              label: context.t.common.delete,
              onPressed: () {},
              destructive: true,
            ),
          ],
        ),
      );

  static Future<void> _showConfirmDialog(BuildContext context) =>
      showDialog<void>(
        context: context,
        builder: (_) => AppConfirmDialog(
          title: context.t.me.componentLibraryConfirmDialog,
          secondaryLabel: context.t.common.cancel,
          primaryLabel: context.t.common.delete,
          destructive: true,
          onPrimary: () {},
        ),
      );
}
