import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/storage/data_reset_controller.dart';
import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_artwork.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_page_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/user_profile.dart';
import '../providers/account_providers.dart';
import '../widgets/settings_back_button.dart';
import '../widgets/settings_load_failure.dart';

class StoragePage extends ConsumerWidget {
  const StoragePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(storageUsageProvider);
    final busy = ref.watch(dataResetControllerProvider);
    return PopScope(
      canPop: !busy,
      child: AbsorbPointer(
        absorbing: busy,
        child: AppPageScaffold(
          title: context.t.me.storage,
          leading: const SettingsBackButton(),
          body: ListView(
            padding: AppPageInsets.of(context),
            children: [
              if (usage.hasError)
                SettingsLoadFailure(
                  onRetry: () => ref.invalidate(storageUsageProvider),
                )
              else
                Skeletonizer(
                  enabled: usage.isLoading,
                  child: _UsageCard(usage: usage.value ?? const StorageUsage()),
                ),
              const Gap(AppSpacing.xl),
              AppPageButton(
                label: busy ? context.t.me.clearing : context.t.me.clearAll,
                icon: AppIcons.delete,
                busy: busy,
                destructive: true,
                onPressed: () => _confirm(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) {
    final t = context.t;
    return showDialog<void>(
      context: context,
      animationStyle: AppMotion.style(context),
      builder: (_) => AppConfirmDialog(
        title: t.me.clearWarning,
        secondaryLabel: t.common.cancel,
        primaryLabel: t.me.confirmClear,
        destructive: true,
        onPrimary: () async {
          final result = await ref
              .read(dataResetControllerProvider.notifier)
              .clear();
          if (context.mounted) {
            showOutcome(
              context,
              failure: result.getLeft().toNullable(),
              success: context.t.me.cleared,
            );
          }
        },
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.usage});
  final StorageUsage usage;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const AppArtwork(BrandArt.files),
      const Gap(AppSpacing.md),
      Text(
        _bytes(usage.totalBytes),
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const Gap(AppSpacing.xs),
      Text(
        context.t.me.usedStorage,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const Gap(AppSpacing.xl),
      GlassGroupedSection(
        quality: AppEffects.qualityOf(context, GlassQuality.standard),
        shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
        margin: AppInsets.section,
        children: [
          AppListTile(
            title: context.t.me.photos,
            icon: AppIcons.album,
            value: _bytes(usage.mediaBytes),
          ),
          AppListTile(
            title: context.t.memory.title,
            icon: AppIcons.folder,
            value: _bytes(usage.memoryBytes),
          ),
          AppListTile(
            title: context.t.me.database,
            icon: AppIcons.chat,
            value: _bytes(usage.databaseBytes),
          ),
          AppListTile(
            title: context.t.me.configuration,
            icon: AppIcons.preferences,
            value: _bytes(usage.settingsBytes),
          ),
        ],
      ),
    ],
  );

  static String _bytes(int value) => switch (value) {
    >= 1073741824 => '${(value / 1073741824).toStringAsFixed(1)} GB',
    >= 1048576 => '${(value / 1048576).toStringAsFixed(1)} MB',
    >= 1024 => '${(value / 1024).toStringAsFixed(1)} KB',
    _ => '$value B',
  };
}
