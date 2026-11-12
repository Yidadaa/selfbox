import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../providers/settings_providers.dart';
import 'added_model_tile.dart';
import 'model_selection_sheet.dart';
import 'primary_button.dart';

class ProviderModelsSection extends HookConsumerWidget {
  const ProviderModelsSection({required this.providerId, super.key});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fetching = useState(false);
    final models = ref.watch(
      aiSettingsProvider.select(
        (settings) =>
            settings.whenData((value) => value.modelsOf(providerId)).value ??
            const [],
      ),
    );
    final added = models
        .where((model) => model.enabled)
        .toList(growable: false);

    Future<void> fetch() async {
      if (fetching.value) return;
      fetching.value = true;
      final result = await ref
          .read(aiSettingsServiceProvider)
          .refreshModels(providerId)
          .run();
      if (!context.mounted) return;
      fetching.value = false;
      showOutcome(
        context,
        failure: result.getLeft().toNullable(),
        success: context.t.settings.provider.fetched,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (added.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: EmptyState(label: context.t.settings.provider.noAddedModels),
          )
        else
          GlassGroupedSection(
            margin: AppInsets.section,
            quality: GlassQuality.standard,
            shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
            header: SectionHeader(context.t.settings.provider.models),
            children: [
              for (final model in added)
                AddedModelTile(key: ValueKey(model.ref), model: model),
            ],
          ),
        const Gap(AppSpacing.md),
        PrimaryButton(
          key: const ValueKey('add-model-button'),
          label: context.t.settings.provider.addModel,
          icon: Icons.add_rounded,
          onTap: () => showModelSelectionSheet(
            context: context,
            providerId: providerId,
            models: models,
          ),
        ),
        const Gap(AppSpacing.xs),
        TextButton.icon(
          onPressed: fetching.value ? null : fetch,
          icon: const Icon(Icons.sync_rounded),
          label: Text(context.t.settings.provider.fetchModels),
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSizes.minTouchTarget),
          ),
        ),
      ],
    );
  }
}
