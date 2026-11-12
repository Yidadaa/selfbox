import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_dialog_tokens.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/ai_settings.dart';
import '../providers/settings_providers.dart';

Future<void> showModelSelectionSheet({
  required BuildContext context,
  required String providerId,
  required List<ModelConfig> models,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: context.glass.bubbleOther,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(AppDialogTokens.radius),
    ),
  ),
  clipBehavior: Clip.antiAlias,
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
      duration: AppMotion.fast,
      curve: AppMotion.emphasized,
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        key: const ValueKey('model-chooser'),
        height: height,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    IconButton(
                      key: const ValueKey('cancel-model-selection'),
                      onPressed: saving.value
                          ? null
                          : () => Navigator.of(context).pop(),
                      tooltip: context.t.common.cancel,
                      icon: const Icon(Icons.close_rounded),
                      constraints: const BoxConstraints.tightFor(
                        width: AppSizes.minTouchTarget,
                        height: AppSizes.minTouchTarget,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        context.t.settings.provider.models,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: context.glass.onBubbleOther),
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('confirm-add-models'),
                      onPressed: saving.value || selected.value.isEmpty
                          ? null
                          : add,
                      child: Text(context.t.settings.provider.addModel),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: GlassTextField(
                  key: const ValueKey('model-search-input'),
                  placeholder: context.t.settings.provider.searchModels,
                  prefixIcon: const Icon(Icons.search_rounded),
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
                            child: CheckboxListTile(
                              key: ValueKey('model-option-${model.modelId}'),
                              value: selected.value.contains(model.modelId),
                              onChanged: saving.value
                                  ? null
                                  : (checked) =>
                                        selected.value = checked == true
                                        ? {...selected.value, model.modelId}
                                        : selected.value.difference({
                                            model.modelId,
                                          }),
                              title: Text(
                                model.modelId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              tileColor: context.glass.bubbleOther,
                              activeColor: context.glass.accent,
                              checkColor: context.glass.onAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                side: BorderSide(
                                  color: context.glass.shadowBorder,
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
