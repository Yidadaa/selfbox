import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_artwork_tokens.dart';
import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ai_composer_glow.dart';
import '../../../../core/widgets/app_action_button.dart';
import '../../../../core/widgets/app_artwork.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/pressable.dart';
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
        const _ButtonsPreview(),
        SectionHeader(context.t.me.componentLibraryIcons),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              AppIcon(AppIcons.chat),
              AppIcon(AppIcons.memory),
              AppIcon(AppIcons.profile),
              AppIcon(AppIcons.ai),
              AppIcon(AppIcons.search),
              AppIcon(AppIcons.settings),
              AppIcon(AppIcons.add),
              AppIcon(AppIcons.send),
            ],
          ),
        ),
        GlassGroupedSection(
          quality: AppEffects.qualityOf(context, GlassQuality.standard),
          shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
          margin: AppInsets.section,
          children: [
            AppListTile(
              icon: AppIcons.preferences,
              title: context.t.me.componentLibraryDialog,
              onTap: () => _showDialogPreview(context),
            ),
            AppListTile(
              icon: AppIcons.warning,
              title: context.t.me.componentLibraryConfirmDialog,
              onTap: () => _showConfirmDialog(context),
            ),
            AppListTile(
              icon: AppIcons.checklist,
              title: context.t.me.componentLibraryTile,
              subtitle: context.t.me.componentLibraryDescription,
            ),
          ],
        ),
        const Gap(AppSpacing.md),
        SectionHeader(context.t.me.componentLibraryEmptyState),
        const Gap(AppSpacing.xs),
        EmptyState(label: context.t.common.notSet),
        const Gap(AppSpacing.xl),
        SectionHeader(context.t.me.componentLibraryArtwork),
        const Gap(AppSpacing.md),
        const _ArtworkPreview(),
        const Gap(AppSpacing.md),
        SectionHeader(context.t.chat.aiMode),
        const _ComposerGlowPreview(),
      ],
    ),
  );

  static Future<void> _showDialogPreview(BuildContext context) =>
      showDialog<void>(
        context: context,
        animationStyle: AppMotion.style(context),
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
        animationStyle: AppMotion.style(context),
        builder: (_) => AppConfirmDialog(
          title: context.t.me.componentLibraryConfirmDialog,
          secondaryLabel: context.t.common.cancel,
          primaryLabel: context.t.common.delete,
          destructive: true,
          onPrimary: () {},
        ),
      );
}

class _ArtworkPreview extends StatelessWidget {
  const _ArtworkPreview();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.md,
    runSpacing: AppSpacing.md,
    children: [
      for (final art in BrandArt.values)
        AppArtwork(art, size: AppArtworkTokens.compact),
    ],
  );
}

class _ComposerGlowPreview extends HookConsumerWidget {
  const _ComposerGlowPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = useState(false);
    const shape = LiquidRoundedSuperellipse(borderRadius: AppRadius.xl);
    final glass = context.glass;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Pressable(
            key: const ValueKey('component-glow-toggle'),
            semanticLabel: context.t.chat.aiMode,
            onTap: () => active.value = !active.value,
            child: ExcludeSemantics(
              child: Text(
                active.value ? context.t.chat.aiStandby : context.t.chat.aiMode,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ),
        AiComposerGlow(
          active: active.value,
          shape: shape,
          child: GlassContainer(
            quality: AppEffects.qualityOf(context, GlassQuality.standard),
            useOwnLayer: true,
            shape: shape,
            settings: LiquidGlassSettings(
              blur: glass.chromeBlur,
              glassColor: glass.composerAiTint,
            ),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              context.t.chat.aiInputHint,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: glass.foregroundMuted),
            ),
          ),
        ),
      ],
    );
  }
}

class _ButtonsPreview extends StatelessWidget {
  const _ButtonsPreview();
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
