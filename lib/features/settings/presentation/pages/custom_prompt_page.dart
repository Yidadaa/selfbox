import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/forms/glass_reactive_text_field.dart';
import '../../../../core/forms/luthor_validator.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_page_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/ai_settings.dart';
import '../providers/custom_prompt_controller.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_back_button.dart';
import '../widgets/settings_load_failure.dart';

class CustomPromptPage extends ConsumerWidget {
  const CustomPromptPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppPageScaffold(
    title: context.t.settings.customPrompt,
    leading: const SettingsBackButton(),
    resizeToAvoidBottomInset: false,
    body: switch (ref.watch(aiSettingsProvider)) {
      AsyncData(:final value) => _PromptForm(initial: value.customPrompt),
      AsyncLoading() => const Skeletonizer(
        child: _PromptForm(initial: '', loading: true),
      ),
      AsyncError() => SettingsLoadFailure(
        onRetry: () => ref.invalidate(aiSettingsProvider),
      ),
    },
  );
}

class _PromptForm extends HookConsumerWidget {
  const _PromptForm({required this.initial, this.loading = false});
  final String initial;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = useMemoized(
      () => FormGroup({
        'prompt': FormControl<String>(
          value: initial,
          validators: [
            luthorValidator(AiSettingsSchema.customPrompt, preserveEmpty: true),
          ],
        ),
      }),
    );
    useEffect(() => form.dispose, [form]);
    final busy = ref.watch(
      customPromptControllerProvider.select((state) => state.isLoading),
    );
    Future<void> save() async {
      form.markAllAsTouched();
      if (!form.valid) return;
      final result = await ref
          .read(customPromptControllerProvider.notifier)
          .save(form.control('prompt').value as String? ?? '');
      if (context.mounted) {
        showOutcome(
          context,
          failure: result.getLeft().toNullable(),
          success: context.t.common.saved,
        );
      }
    }

    return ReactiveForm(
      formGroup: form,
      child: AnimatedPadding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        duration: AppMotion.duration(context, AppMotion.medium),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: AppPageInsets.of(context),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    GlassReactiveTextField<String>(
                      formControlName: 'prompt',
                      label: context.t.settings.customPrompt,
                      placeholder: context.t.settings.customPromptHint,
                      keyboardType: TextInputType.multiline,
                      minLines: 8,
                      maxLines: 12,
                    ),
                  ],
                ),
              ),
              _PromptSaveButton(busy: busy, onSave: loading ? null : save),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptSaveButton extends ConsumerWidget {
  const _PromptSaveButton({required this.busy, required this.onSave});
  final bool busy;
  final VoidCallback? onSave;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppInsets.pageHorizontal,
      AppSpacing.md,
      AppInsets.pageHorizontal,
      MediaQuery.paddingOf(context).bottom + AppSpacing.md,
    ),
    child: AppPageButton(
      label: context.t.common.save,
      busy: busy,
      onPressed: onSave,
    ),
  );
}
