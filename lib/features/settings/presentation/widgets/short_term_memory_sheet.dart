import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/forms/luthor_validator.dart';
import '../../../../core/theme/app_dialog_tokens.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_action_button.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/ai_settings.dart';
import '../providers/settings_providers.dart';

Future<void> showShortTermMemorySheet({
  required BuildContext context,
  required int initialPercent,
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
  builder: (_) => ShortTermMemorySheet(initialPercent: initialPercent),
);

class ShortTermMemorySheet extends HookConsumerWidget {
  const ShortTermMemorySheet({required this.initialPercent, super.key});

  final int initialPercent;
  static const _percent = 'percent';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saving = useState(false);
    final form = useMemoized(
      () => FormGroup({
        _percent: FormControl<int>(
          value: initialPercent.clamp(
            AiSettings.minShortTermMemoryPercent,
            AiSettings.maxShortTermMemoryPercent,
          ),
          validators: [
            luthorValidator(AiSettingsSchema.shortTermMemoryPercent),
          ],
        ),
      }),
      [initialPercent],
    );
    useEffect(() => form.dispose, [form]);

    Future<void> save() async {
      final percent = form.control(_percent).value;
      if (saving.value || !form.valid || percent is! int) return;
      saving.value = true;
      final result = await ref
          .read(aiSettingsServiceProvider)
          .setShortTermMemoryPercent(percent)
          .run();
      if (!context.mounted) return;
      result.match((failure) {
        saving.value = false;
        showOutcome(context, failure: failure);
      }, (_) => Navigator.of(context).pop());
    }

    return ReactiveForm(
      formGroup: form,
      child: _SheetContent(
        controlName: _percent,
        saving: saving.value,
        onSave: save,
      ),
    );
  }
}

class _SheetContent extends StatelessWidget {
  const _SheetContent({
    required this.controlName,
    required this.saving,
    required this.onSave,
  });

  final String controlName;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t.settings.shortTermMemory,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: context.glass.onBubbleOther),
          ),
          const Gap(AppSpacing.xl),
          _MemoryBudgetControl(controlName: controlName, enabled: !saving),
          const Gap(AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                child: AppActionButton(
                  key: const ValueKey('short-term-memory-cancel'),
                  label: context.t.common.cancel,
                  onPressed: saving ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                child: AppActionButton(
                  key: const ValueKey('short-term-memory-save'),
                  label: context.t.common.save,
                  variant: AppActionButtonVariant.primary,
                  onPressed: saving ? null : onSave,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _MemoryBudgetControl extends ConsumerWidget {
  const _MemoryBudgetControl({
    required this.controlName,
    required this.enabled,
  });

  final String controlName;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(
      aiSettingsProvider.select((state) => state.asData?.value.resolvedModel),
    );
    final glass = context.glass;
    return ReactiveValueListenableBuilder<int>(
      formControlName: controlName,
      builder: (context, control, _) {
        final percent =
            control.value ?? AiSettings.defaultShortTermMemoryPercent;
        final tokens = model?.shortTermMemoryTokens(percent);
        final estimate = tokens == null
            ? context.t.common.notSet
            : NumberFormat.decimalPattern(
                LocaleSettings.currentLocale.languageTag,
              ).format(tokens);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MemoryPercentSlider(
              percent: percent,
              onChanged: enabled ? (value) => control.updateValue(value) : null,
            ),
            const Gap(AppSpacing.xl),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                estimate,
                key: const ValueKey('short-term-memory-tokens'),
                maxLines: 1,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: glass.onBubbleOther,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MemoryPercentSlider extends StatelessWidget {
  const _MemoryPercentSlider({required this.percent, required this.onChanged});

  final int percent;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final change = onChanged;
    String percentage(int value) => context.t.settings.memoryPercent(
      value: value.clamp(
        AiSettings.minShortTermMemoryPercent,
        AiSettings.maxShortTermMemoryPercent,
      ),
    );
    // The package reports position within the range as 0–100%; expose the
    // actual context share (10–60%) to assistive technologies instead.
    return Semantics(
      key: const ValueKey('short-term-memory-semantics'),
      label: context.t.settings.shortTermMemory,
      value: percentage(percent),
      increasedValue: percentage(percent + 1),
      decreasedValue: percentage(percent - 1),
      slider: true,
      enabled: change != null,
      excludeSemantics: true,
      onIncrease:
          change != null && percent < AiSettings.maxShortTermMemoryPercent
          ? () => change(percent + 1)
          : null,
      onDecrease:
          change != null && percent > AiSettings.minShortTermMemoryPercent
          ? () => change(percent - 1)
          : null,
      child: Row(
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.minTouchTarget,
              ),
              child: GlassSlider(
                key: const ValueKey('short-term-memory-slider'),
                value: percent.toDouble(),
                min: AiSettings.minShortTermMemoryPercent.toDouble(),
                max: AiSettings.maxShortTermMemoryPercent.toDouble(),
                divisions:
                    AiSettings.maxShortTermMemoryPercent -
                    AiSettings.minShortTermMemoryPercent,
                quality: GlassQuality.standard,
                activeColor: glass.accent,
                inactiveColor: glass.dialogActionFill,
                onChanged: change == null
                    ? null
                    : (value) => change(value.round()),
                onChangeEnd: (_) => HapticFeedback.selectionClick(),
              ),
            ),
          ),
          const Gap(AppSpacing.md),
          Text(
            context.t.settings.memoryPercent(value: percent),
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: glass.onBubbleOther),
          ),
        ],
      ),
    );
  }
}
