import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/forms/glass_reactive_text_field.dart';
import '../../../../core/forms/luthor_validator.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/ai_settings.dart';
import '../providers/settings_providers.dart';
import '../widgets/primary_button.dart';
import '../widgets/settings_labels.dart';

/// Per-model capabilities and budgets.
class ModelPage extends ConsumerWidget {
  const ModelPage({required this.providerId, required this.modelId, super.key});

  final String providerId;
  final String modelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(
      aiSettingsProvider.select(
        (s) => s.whenData(
          (v) => v
              .modelsOf(providerId)
              .where((m) => m.modelId == modelId)
              .firstOrNull,
        ),
      ),
    );
    return switch (model) {
      AsyncData(value: final ModelConfig config) => _ModelForm(model: config),
      AsyncLoading() => AppPageScaffold(
        title: modelId,
        leading: const _Back(),
        body: const SizedBox.expand(),
      ),
      _ => AppPageScaffold(
        title: modelId,
        leading: const _Back(),
        body: EmptyState(label: context.t.settings.errors.generic),
      ),
    };
  }
}

class _Back extends StatelessWidget {
  const _Back();

  @override
  Widget build(BuildContext context) => GlassIconButton(
    icon: const Icon(Icons.arrow_back_ios_new_rounded),
    semanticLabel: context.t.common.close,
    onPressed: () => Navigator.of(context).maybePop(),
  );
}

class _ModelForm extends HookConsumerWidget {
  const _ModelForm({required this.model});

  final ModelConfig model;

  static const _enabled = 'enabled';
  static const _input = 'input';
  static const _output = 'output';
  static const _images = 'images';
  static const _reasoning = 'reasoning';
  static const _effort = 'effort';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final saving = useState(false);
    final form = useMemoized(
      () => FormGroup({
        _enabled: FormControl<bool>(value: model.enabled),
        _input: FormControl<int>(
          value: model.maxInputTokens,
          validators: [luthorValidator(AiSettingsSchema.inputTokens)],
        ),
        _output: FormControl<int>(
          value: model.maxOutputTokens,
          validators: [luthorValidator(AiSettingsSchema.outputTokens)],
        ),
        _images: FormControl<bool>(value: model.supportsImages),
        _reasoning: FormControl<bool>(value: model.supportsReasoning),
        _effort: FormControl<ReasoningEffort>(value: model.reasoningEffort),
      }),
    );
    useEffect(() => form.dispose, [form]);

    Future<void> save() async {
      form.markAllAsTouched();
      if (!form.valid || saving.value) return;
      T value<T>(String name) => form.control(name).value as T;
      saving.value = true;
      final result = await ref
          .read(aiSettingsServiceProvider)
          .saveModel(
            model.copyWith(
              enabled: value<bool>(_enabled),
              maxInputTokens: value<int>(_input),
              maxOutputTokens: value<int>(_output),
              supportsImages: value<bool>(_images),
              supportsReasoning: value<bool>(_reasoning),
              reasoningEffort: value<ReasoningEffort>(_effort),
            ),
          )
          .run();
      if (!context.mounted) return;
      saving.value = false;
      showOutcome(
        context,
        failure: result.getLeft().toNullable(),
        success: t.common.saved,
      );
      if (result.isRight()) await Navigator.of(context).maybePop();
    }

    return AppPageScaffold(
      title: model.modelId,
      leading: const _Back(),
      body: ReactiveForm(
        formGroup: form,
        child: ListView(
          padding: AppPageInsets.of(context),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            GlassGroupedSection(
              margin: AppInsets.section,
              quality: GlassQuality.standard,
              shape: const LiquidRoundedSuperellipse(
                borderRadius: AppRadius.lg,
              ),
              children: [
                _SwitchRow(control: _enabled, label: t.settings.model.enabled),
                _SwitchRow(control: _images, label: t.settings.model.images),
                _SwitchRow(
                  control: _reasoning,
                  label: t.settings.model.reasoning,
                ),
              ],
            ),
            ReactiveValueListenableBuilder<bool>(
              formControlName: _reasoning,
              builder: (context, control, _) => control.value ?? false
                  ? const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.lg),
                      child: _EffortPicker(control: _effort),
                    )
                  : const SizedBox.shrink(),
            ),
            const Gap(AppSpacing.lg),
            GlassContainer.card(
              quality: GlassQuality.standard,
              shape: const LiquidRoundedSuperellipse(
                borderRadius: AppRadius.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassReactiveTextField<int>(
                    formControlName: _input,
                    label: t.settings.model.inputTokens,
                    keyboardType: TextInputType.number,
                    valueAccessor: IntValueAccessor(),
                  ),
                  const Gap(AppSpacing.md),
                  GlassReactiveTextField<int>(
                    formControlName: _output,
                    label: t.settings.model.outputTokens,
                    keyboardType: TextInputType.number,
                    valueAccessor: IntValueAccessor(),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.lg),
            PrimaryButton(
              label: t.common.save,
              busy: saving.value,
              onTap: save,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.control, required this.label});

  final String control;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ReactiveValueListenableBuilder<bool>(
      formControlName: control,
      builder: (context, c, _) => AppListTile(
        title: label,
        trailing: GlassSwitch(
          value: c.value ?? false,
          onChanged: (value) => c.value = value,
        ),
      ),
    );
  }
}

class _EffortPicker extends StatelessWidget {
  const _EffortPicker({required this.control});

  final String control;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: Text(
            context.t.settings.model.effort,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: context.glass.foregroundMuted),
          ),
        ),
        const Gap(AppSpacing.xs),
        ReactiveValueListenableBuilder<ReasoningEffort>(
          formControlName: control,
          builder: (context, c, _) => GlassSegmentedControl(
            selectedTextStyle: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w600),
            unselectedTextStyle: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: context.glass.foregroundMuted),
            selectedIndex: ReasoningEffort.values.indexOf(
              c.value ?? ReasoningEffort.medium,
            ),
            segments: [
              for (final effort in ReasoningEffort.values)
                GlassSegment(label: effort.label(context)),
            ],
            onSegmentSelected: (i) => c.value = ReasoningEffort.values[i],
          ),
        ),
      ],
    );
  }
}
