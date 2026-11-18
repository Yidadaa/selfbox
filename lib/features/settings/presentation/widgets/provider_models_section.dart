import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_artwork_tokens.dart';
import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_artwork.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_page_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../providers/settings_providers.dart';
import 'added_model_tile.dart';
import 'model_selection_sheet.dart';

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
    final availableCount = models.length - added.length;

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
            child: EmptyState(
              label: context.t.settings.provider.noAddedModels,
              illustration: BrandArt.empty,
              illustrationSize: AppArtworkTokens.compact,
            ),
          )
        else
          GlassGroupedSection(
            margin: AppInsets.section,
            surfaceStyle: GlassSurfaceStyle.solid,
            shape: LiquidRoundedSuperellipse(
              borderRadius: AppRadius.lg,
              side: AppEffects.solidBorderOf(context),
            ),
            header: SectionHeader(context.t.settings.provider.models),
            children: [
              for (final model in added)
                AddedModelTile(key: ValueKey(model.ref), model: model),
            ],
          ),
        const Gap(AppSpacing.md),
        AppPageButton(
          key: const ValueKey('add-model-button'),
          label: context.t.settings.provider.addModelAvailable(
            count: availableCount,
          ),
          icon: AppIcons.add,
          iconSize: AppSizes.iconSm,
          onPressed: () => showModelSelectionSheet(
            context: context,
            providerId: providerId,
            models: models,
          ),
        ),
        const Gap(AppSpacing.xs),
        AppPageButton(
          key: const ValueKey('fetch-models-button'),
          onPressed: fetching.value ? null : fetch,
          icon: AppIcons.download,
          iconSize: AppSizes.iconSm,
          label: context.t.settings.provider.fetchModels,
          busy: fetching.value,
        ),
      ],
    );
  }
}
