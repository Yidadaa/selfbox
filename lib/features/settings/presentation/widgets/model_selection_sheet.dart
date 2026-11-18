import 'dart:math' as math;

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_artwork_tokens.dart';
import '../../../../core/theme/app_dialog_tokens.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_action_button.dart';
import '../../../../core/widgets/app_artwork.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_modal_surface.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/ai_settings.dart';
import '../providers/settings_providers.dart';

Future<void> showModelSelectionSheet({
  required BuildContext context,
  required String providerId,
  required List<ModelConfig> models,
}) => showAppBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => ModelSelectionSheet(providerId: providerId, models: models),
);

class ModelSelectionSheet extends HookConsumerWidget {
  const ModelSelectionSheet({
    required this.providerId,
    required this.models,
    super.key,
  });

  final String providerId;
  final List<ModelConfig> models;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = useState('');
    final selected = useState(<String>{});
    final saving = useState(false);
    final scroll = useScrollController();
    final candidates = useMemoized(
      () => models.where((model) => !model.enabled).toList(growable: false),
      [models],
    );
    final filtered = useMemoized(() {
      final search = query.value.trim().toLowerCase();
      return search.isEmpty
          ? candidates
          : candidates
                .where((model) => model.modelId.toLowerCase().contains(search))
                .toList(growable: false);
    }, [candidates, query.value]);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final viewport = MediaQuery.sizeOf(context).height;
    final available =
        viewport - keyboard - MediaQuery.paddingOf(context).top - AppSpacing.xl;
    final height = math.max(
      0.0,
      math.min(viewport * AppDialogTokens.modelSheetFraction, available),
    );

    Future<void> add() async {
      if (saving.value || selected.value.isEmpty) return;
      saving.value = true;
      final result = await ref
          .read(aiSettingsServiceProvider)
          .addModels(providerId, selected.value)
          .run();
      if (!context.mounted) return;
      saving.value = false;
      if (result.isRight()) {
        Navigator.of(context).pop();
      } else {
        showOutcome(context, failure: result.getLeft().toNullable());
      }
    }

    return AnimatedPadding(
      duration: AppMotion.duration(context, AppMotion.fast),
      curve: AppMotion.emphasized,
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        key: const ValueKey('model-chooser'),
        width: double.infinity,
        height: height,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                key: const ValueKey('model-selection-header'),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    AppActionIconButton(
                      key: const ValueKey('cancel-model-selection'),
                      onPressed: saving.value
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: AppIcons.close,
                      tooltip: context.t.common.cancel,
                    ),
                    Expanded(
                      child: Text(
                        context.t.settings.provider.models,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: context.glass.onBubbleOther),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: AppActionButton(
                          key: const ValueKey('confirm-add-models'),
                          expand: false,
                          variant: AppActionButtonVariant.primary,
                          onPressed: saving.value || selected.value.isEmpty
                              ? null
                              : add,
                          label: context.t.settings.provider.addModel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: GlassTextField(
                  key: const ValueKey('model-search-input'),
                  placeholder: context.t.settings.provider.searchModels,
                  prefixIcon: const AppIcon(AppIcons.search),
                  surfaceStyle: GlassSurfaceStyle.solid,
                  shape: const LiquidRoundedSuperellipse(
                    borderRadius: AppRadius.sm,
                  ),
                  onChanged: (value) {
                    query.value = value;
                    if (scroll.hasClients) scroll.jumpTo(0);
                  },
                ),
              ),
              const Gap(AppSpacing.xs),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        illustration: query.value.trim().isEmpty
                            ? BrandArt.empty
                            : BrandArt.search,
                        illustrationSize: AppArtworkTokens.feedback,
                        label: query.value.trim().isEmpty
                            ? context.t.settings.provider.noAvailableModels
                            : context.t.settings.provider.noSearchResults,
                      )
                    : ListView.builder(
                        key: const ValueKey('model-selection-list'),
                        controller: scroll,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        itemExtent: AppSizes.minTouchTarget + AppSpacing.md,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final model = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xxs,
                            ),
                            child: Semantics(
                              key: ValueKey('model-option-${model.modelId}'),
                              checked: selected.value.contains(model.modelId),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: context.glass.bubbleOther,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                  border: Border.all(
                                    color: context.glass.shadowBorder,
                                  ),
                                ),
                                child: AppListTile(
                                  title: model.modelId,
                                  icon: selected.value.contains(model.modelId)
                                      ? AppIcons.checked
                                      : AppIcons.unchecked,
                                  showChevron: false,
                                  onTap: saving.value
                                      ? null
                                      : () => selected.value =
                                            selected.value.contains(
                                              model.modelId,
                                            )
                                            ? selected.value.difference({
                                                model.modelId,
                                              })
                                            : {
                                                ...selected.value,
                                                model.modelId,
                                              },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
