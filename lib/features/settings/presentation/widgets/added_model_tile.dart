import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/ai_settings.dart';
import '../providers/settings_providers.dart';
import 'model_settings_sheet.dart';
import 'settings_labels.dart';

class AddedModelTile extends HookConsumerWidget {
  const AddedModelTile({required this.model, super.key});

  final ModelConfig model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = useState(false);

    Future<void> update(ModelConfig next) async {
      if (busy.value) return;
      busy.value = true;
      final result = await ref
          .read(aiSettingsServiceProvider)
          .saveModel(next)
          .run();
      if (!context.mounted) return;
      busy.value = false;
      if (result.isLeft()) {
        showOutcome(context, failure: result.getLeft().toNullable());
      }
    }

    return Column(
      children: [
        AppListTile(
          key: ValueKey('model-open-${model.modelId}'),
          title: model.modelId,
          onTap: () => showModelSettingsSheet(context: context, model: model),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: _CapabilityToggle(
                  label: context.t.settings.model.images,
                  value: model.supportsImages,
                  busy: busy.value,
                  switchKey: ValueKey('model-images-${model.modelId}'),
                  onChanged: (value) =>
                      update(model.copyWith(supportsImages: value)),
                ),
              ),
              const Gap(AppSpacing.xs),
              Expanded(
                child: _CapabilityToggle(
                  label: context.t.settings.model.reasoning,
                  value: model.supportsReasoning,
                  busy: busy.value,
                  switchKey: ValueKey('model-reasoning-${model.modelId}'),
                  onChanged: (value) =>
                      update(model.copyWith(supportsReasoning: value)),
                ),
              ),
            ],
          ),
        ),
        if (model.supportsReasoning)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: GlassSegmentedControl(
              key: ValueKey('model-effort-${model.modelId}'),
              height: AppSizes.smallTabHeight,
              quality: GlassQuality.standard,
              selectedIndex: ReasoningEffort.values.indexOf(
                model.reasoningEffort,
              ),
              selectedTextStyle: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
              unselectedTextStyle: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: context.glass.foregroundMuted),
              segments: [
                for (final effort in ReasoningEffort.values)
                  GlassSegment(label: effort.label(context)),
              ],
              onSegmentSelected: (index) {
                if (busy.value) return;
                update(
                  model.copyWith(
                    reasoningEffort: ReasoningEffort.values[index],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CapabilityToggle extends StatelessWidget {
  const _CapabilityToggle({
    required this.label,
    required this.value,
    required this.busy,
    required this.switchKey,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool busy;
  final Key switchKey;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : () => onChanged(!value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: context.glass.foregroundMuted),
              ),
            ),
            AbsorbPointer(
              absorbing: busy,
              child: GlassSwitch(
                key: switchKey,
                quality: GlassQuality.standard,
                value: value,
                semanticLabel: label,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
