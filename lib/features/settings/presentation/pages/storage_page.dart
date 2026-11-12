import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/storage/data_reset_controller.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/user_profile.dart';
import '../providers/account_providers.dart';
import '../widgets/primary_button.dart';
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
              Text(
                context.t.me.databaseNote,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: context.glass.foregroundMuted),
              ),
              const Gap(AppSpacing.xxl),
              PrimaryButton(
                label: busy ? context.t.me.clearing : context.t.me.clearAll,
                icon: Icons.delete_outline_rounded,
                busy: busy,
                onTap: () => _confirm(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) =>
      showGlassActionSheet<void>(
        context: context,
        title: context.t.me.clearWarning,
        cancelLabel: context.t.common.cancel,
        actions: [
          GlassActionSheetAction(
            label: context.t.me.confirmClear,
            style: GlassActionSheetStyle.destructive,

            onPressed: () async {
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
        ],
      );
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.usage});
  final StorageUsage usage;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(
        Icons.storage_rounded,
        size: AppSizes.iconHero,
        color: context.glass.accent,
      ),
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
        quality: GlassQuality.standard,
        margin: AppInsets.section,
        children: [
          AppListTile(
            title: context.t.me.photos,
            icon: Icons.photo_library_outlined,
            value: _bytes(usage.mediaBytes),
          ),
          AppListTile(
            title: context.t.memory.title,
            icon: Icons.folder_outlined,
            value: _bytes(usage.memoryBytes),
          ),
          AppListTile(
            title: context.t.me.database,
            icon: Icons.chat_bubble_outline_rounded,
            value: _bytes(usage.databaseBytes),
          ),
          AppListTile(
            title: context.t.me.configuration,
            icon: Icons.tune_rounded,
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
