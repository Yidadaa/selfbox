import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/ai_settings.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_back_button.dart';
import '../widgets/settings_labels.dart';
import '../widgets/settings_load_failure.dart';
import '../widgets/settings_picker_sheet.dart';
import '../widgets/short_term_memory_sheet.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final active = settings.resolvedModel;
    return ListView(
      padding: AppPageInsets.of(context),
      children: [
        GlassGroupedSection(
          margin: AppInsets.section,
          quality: GlassQuality.standard,
          shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
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
              title: t.settings.shortTermMemory,
              value: t.settings.memoryPercent(
                value: settings.shortTermMemoryPercent,
              ),
              onTap: () => showShortTermMemorySheet(
                context: context,
                initialPercent: settings.shortTermMemoryPercent,
              ),
            ),
          ],
        ),
        const Gap(AppSpacing.xl),
        GlassGroupedSection(
          margin: AppInsets.section,
          quality: GlassQuality.standard,
          shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
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

  Future<void> _pickModel(BuildContext context, WidgetRef ref) {
    final models = settings.enabledModels;
    final currentIndex = models.indexWhere(
      (model) => model.ref == settings.resolvedModel?.ref,
    );
    return showSettingsPicker(
      context: context,
      title: context.t.settings.activeModel,
      pickerKey: const ValueKey('model-picker'),
      labels: [
        for (final model in models)
          '${settings.providerOf(model.providerId)?.name ?? model.providerId} '
              '· ${model.modelId}',
      ],
      initialIndex: currentIndex < 0 ? 0 : currentIndex,
      onSave: (index) async {
        final result = await ref
            .read(aiSettingsServiceProvider)
            .selectModel(models[index].ref)
            .run();
        if (context.mounted) {
          showOutcome(context, failure: result.getLeft().toNullable());
        }
        return result.isRight();
      },
    );
  }
}
