import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/app_preferences.dart';
import '../providers/app_preferences_controller.dart';
import 'settings_picker_sheet.dart';

class GeneralEffectsSection extends ConsumerWidget {
  const GeneralEffectsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesControllerProvider);
    final labels = context.t.general;
    return GlassGroupedSection(
      margin: AppInsets.section,
      quality: AppEffects.qualityOf(context, GlassQuality.standard),
      shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
      children: [
        AppListTile(
          icon: AppIcons.rendering,
          title: labels.rendering,
          value: switch (preferences.renderQuality) {
            AppRenderQuality.minimal => labels.minimal,
            AppRenderQuality.standard => labels.standard,
            AppRenderQuality.premium => labels.premium,
          },
          onTap: () => _pickQuality(context, ref, preferences.renderQuality),
        ),
        AppListTile(
          icon: AppIcons.animation,
          title: labels.animations,
          onTap: () =>
              _setAnimations(context, ref, !preferences.animationsEnabled),
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTouchTarget,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: GlassSwitch(
                key: const ValueKey('animations-switch'),
                value: preferences.animationsEnabled,
                semanticLabel: labels.animations,
                onChanged: (value) => _setAnimations(context, ref, value),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _setAnimations(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final result = await ref
        .read(appPreferencesControllerProvider.notifier)
        .setAnimationsEnabled(value);
    if (context.mounted && result.isLeft()) {
      showOutcome(context, failure: result.getLeft().toNullable());
    }
  }

  Future<void> _pickQuality(
    BuildContext context,
    WidgetRef ref,
    AppRenderQuality current,
  ) => showSettingsPicker(
    context: context,
    title: context.t.general.rendering,
    pickerKey: const ValueKey('render-quality-picker'),
    labels: [
      context.t.general.minimal,
      context.t.general.standard,
      context.t.general.premium,
    ],
    initialIndex: AppRenderQuality.values.indexOf(current),
    onSave: (index) async {
      final result = await ref
          .read(appPreferencesControllerProvider.notifier)
          .setRenderQuality(AppRenderQuality.values[index]);
      if (context.mounted) {
        showOutcome(context, failure: result.getLeft().toNullable());
      }
      return result.isRight();
    },
  );
}
