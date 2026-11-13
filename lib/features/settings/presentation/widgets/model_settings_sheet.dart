import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/forms/glass_reactive_text_field.dart';
import '../../../../core/forms/luthor_validator.dart';
import '../../../../core/theme/app_dialog_tokens.dart';
import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_action_button.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/ai_settings.dart';
import '../providers/settings_providers.dart';
import 'model_test_control.dart';
import 'primary_button.dart';

Future<void> showModelSettingsSheet({
  required BuildContext context,
  required ModelConfig model,
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
  builder: (_) => ModelSettingsSheet(model: model),
);

class ModelSettingsSheet extends HookConsumerWidget {
  const ModelSettingsSheet({required this.model, super.key});

  final ModelConfig model;

  static const _input = 'input';
  static const _output = 'output';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saving = useState(false);
    final form = useMemoized(
      () => FormGroup({
        _input: FormControl<int>(
          value: model.maxInputTokens,
          validators: [luthorValidator(AiSettingsSchema.inputTokens)],
        ),
        _output: FormControl<int>(
          value: model.maxOutputTokens,
          validators: [luthorValidator(AiSettingsSchema.outputTokens)],
        ),
      }),
      [model.ref],
    );
    useEffect(() => form.dispose, [form]);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final viewport = MediaQuery.sizeOf(context).height;
    final available =
        viewport - keyboard - MediaQuery.paddingOf(context).top - AppSpacing.xl;
    final height = math.max(
      0.0,
      math.min(viewport * AppDialogTokens.modelSheetFraction, available),
    );

    Future<void> save() async {
      form.markAllAsTouched();
      if (!form.valid || saving.value) return;
      saving.value = true;
      final result = await ref
          .read(aiSettingsServiceProvider)
          .saveModel(
            model.copyWith(
              maxInputTokens: form.control(_input).value as int,
              maxOutputTokens: form.control(_output).value as int,
            ),
          )
          .run();
      if (!context.mounted) return;
      saving.value = false;
      if (result.isRight()) {
        Navigator.of(context).pop();
      } else {
        showOutcome(context, failure: result.getLeft().toNullable());
      }
    }

    Future<void> remove() async {
      final result = await ref
          .read(aiSettingsServiceProvider)
          .removeModel(model.ref)
          .run();
      if (!context.mounted) return;
      if (result.isRight()) {
        Navigator.of(context).pop();
      } else {
        showOutcome(context, failure: result.getLeft().toNullable());
      }
    }

    void confirmRemove() {
      final title = model.modelId;
      final cancel = context.t.common.cancel;
      final delete = context.t.settings.model.delete;
      showDialog<void>(
        context: context,
        builder: (_) => AppConfirmDialog(
          title: title,
          secondaryLabel: cancel,
          primaryLabel: delete,
          destructive: true,
          onPrimary: remove,
        ),
      );
    }

    return AnimatedPadding(
      duration: AppMotion.fast,
      curve: AppMotion.emphasized,
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        key: const ValueKey('model-settings-sheet'),
        height: height,
        child: SafeArea(
          top: false,
          child: ReactiveForm(
            formGroup: form,
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
                      AppActionIconButton(
                        tooltip: context.t.common.close,
                        onPressed: saving.value
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: Icons.close_rounded,
                      ),
                      Expanded(
                        child: Text(
                          model.modelId,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: context.glass.onBubbleOther),
                        ),
                      ),
                      const Gap(AppSizes.minTouchTarget),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    children: [
                      ModelTestControl(model: model),
                      const Gap(AppSpacing.md),
                      GlassReactiveTextField<int>(
                        key: const ValueKey('model-input-tokens'),
                        formControlName: _input,
                        label: context.t.settings.model.inputTokens,
                        keyboardType: TextInputType.number,
                        valueAccessor: IntValueAccessor(),
                      ),
                      const Gap(AppSpacing.md),
                      GlassReactiveTextField<int>(
                        key: const ValueKey('model-output-tokens'),
                        formControlName: _output,
                        label: context.t.settings.model.outputTokens,
                        keyboardType: TextInputType.number,
                        valueAccessor: IntValueAccessor(),
                      ),
                      const Gap(AppSpacing.xl),
                      PrimaryButton(
                        key: const ValueKey('save-model-settings'),
                        label: context.t.common.save,
                        busy: saving.value,
                        onTap: save,
                      ),
                      const Gap(AppSpacing.md),
                      AppActionButton(
                        key: const ValueKey('delete-model-button'),
                        onPressed: saving.value ? null : confirmRemove,
                        icon: Icons.delete_outline_rounded,
                        label: context.t.settings.model.delete,
                        variant: AppActionButtonVariant.destructive,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
