import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/ai_settings.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_back_button.dart';
import '../widgets/settings_labels.dart';
import '../widgets/settings_load_failure.dart';

class AiProvidersPage extends ConsumerWidget {
  const AiProvidersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);
    return AppPageScaffold(
      title: context.t.me.providers,
      leading: const SettingsBackButton(),
      body: switch (settings) {
        AsyncData(:final value) => _SettingsList(settings: value),
        AsyncError() => SettingsLoadFailure(
          onRetry: () => ref.invalidate(aiSettingsProvider),
        ),
        AsyncLoading() => const Skeletonizer(
          child: _SettingsList(settings: AiSettings()),
        ),
      },
    );
  }
}

class _SettingsList extends ConsumerWidget {
  const _SettingsList({required this.settings});

  final AiSettings settings;

  static const _historyPresets = [0, 5, 10, 20, 40, 80];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final active = settings.resolvedModel;
    return ListView(
      padding: AppPageInsets.of(context),
      children: [
        GlassGroupedSection(
          margin: AppInsets.section,
          quality: GlassQuality.premium,
          header: SectionHeader(t.settings.aiSection),
          children: [
            AppListTile(
              icon: Icons.auto_awesome_outlined,
              title: t.settings.activeModel,
              value: active?.modelId ?? t.common.notSet,
              onTap: settings.enabledModels.isEmpty
                  ? null
                  : () => _pickModel(context, ref),
            ),
            AppListTile(
              icon: Icons.history_rounded,
              title: t.settings.historyTurns,
              value: '${settings.historyTurns}',
              onTap: () => _pickHistory(context, ref),
            ),
          ],
        ),
        const Gap(AppSpacing.xl),
        GlassGroupedSection(
          margin: AppInsets.section,
          quality: GlassQuality.premium,
          header: SectionHeader(t.settings.providers),
          children: [
            for (final provider in settings.providers)
              AppListTile(
                icon: Icons.dns_outlined,
                title: provider.name,
                subtitle:
                    '${provider.format.label(context)} · '
                    '${settings.modelsOf(provider.id).where((m) => m.enabled).length}',
                onTap: () => ProviderRoute(id: provider.id).push<void>(context),
              ),
            AppListTile(
              icon: Icons.add_rounded,
              title: t.settings.addProvider,
              onTap: () => const ProviderRoute().push<void>(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickModel(BuildContext context, WidgetRef ref) =>
      showGlassActionSheet<void>(
        context: context,
        title: context.t.settings.activeModel,
        cancelLabel: context.t.common.cancel,
        actions: [
          for (final model in settings.enabledModels)
            GlassActionSheetAction(
              label: model.modelId,
              icon: model.ref == settings.resolvedModel?.ref
                  ? const Icon(Icons.check_rounded)
                  : null,
              onPressed: () async {
                final result = await ref
                    .read(aiSettingsServiceProvider)
                    .selectModel(model.ref)
                    .run();
                if (context.mounted) {
                  showOutcome(context, failure: result.getLeft().toNullable());
                }
              },
            ),
        ],
      );

  Future<void> _pickHistory(BuildContext context, WidgetRef ref) =>
      showGlassActionSheet<void>(
        context: context,
        title: context.t.settings.historyTurns,
        cancelLabel: context.t.common.cancel,
        actions: [
          for (final turns in _historyPresets)
            GlassActionSheetAction(
              label: '$turns',
              icon: turns == settings.historyTurns
                  ? const Icon(Icons.check_rounded)
                  : null,
              onPressed: () => ref
                  .read(aiSettingsServiceProvider)
                  .setHistoryTurns(turns)
                  .run(),
            ),
        ],
      );
}
