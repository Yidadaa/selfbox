import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../gen/i18n/strings.g.dart';
import '../theme/app_glass_theme.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Localized copy for the Luthor issue codes emitted by `luthorValidator`.
Map<String, ValidationMessageFunction> formErrorMessages(BuildContext context) {
  final e = context.t.forms;
  return {
    'required': (_) => e.required,
    'invalidUrl': (_) => e.url,
    'invalidType': (_) => e.number,
    'tooSmall': (_) => e.tooSmall,
    'tooBig': (_) => e.tooBig,
    'tooShort': (_) => e.required,
    'tooLong': (_) => e.tooLong,
  };
}

/// Label + glass text field bound to a reactive_forms control, with the
/// error shown under the field once it has been touched.
class GlassReactiveTextField<T> extends HookWidget {
  const GlassReactiveTextField({
    required this.formControlName,
    required this.label,
    this.placeholder,
    this.keyboardType,
    this.obscureText = false,
    this.valueAccessor,
    super.key,
  });

  final String formControlName;
  final String label;
  final String? placeholder;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ControlValueAccessor<T, String>? valueAccessor;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    return ReactiveFormField<T, String>(
      formControlName: formControlName,
      valueAccessor: valueAccessor,
      validationMessages: formErrorMessages(context),
      builder: (field) => _FieldBody<T>(
        field: field,
        label: label,
        placeholder: placeholder,
        keyboardType: keyboardType,
        obscureText: obscureText,
        labelStyle: text.labelLarge?.copyWith(color: glass.foregroundMuted),
        errorStyle: text.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

class _FieldBody<T> extends HookWidget {
  const _FieldBody({
    required this.field,
    required this.label,
    required this.placeholder,
    required this.keyboardType,
    required this.obscureText,
    required this.labelStyle,
    required this.errorStyle,
  });

  final ReactiveFormFieldState<T, String> field;
  final String label;
  final String? placeholder;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextStyle? labelStyle;
  final TextStyle? errorStyle;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: field.value ?? '');
    final focus = useFocusNode();
    // Programmatic resets (e.g. form.patchValue) flow back into the field.
    if ((field.value ?? '') != controller.text && !focus.hasFocus) {
      controller.text = field.value ?? '';
    }
    useEffect(() {
      void onFocus() {
        if (!focus.hasFocus) field.control.markAsTouched();
      }

      focus.addListener(onFocus);
      return () => focus.removeListener(onFocus);
    }, [focus]);

    final error = field.errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xxs),
          child: Text(label, style: labelStyle),
        ),
        const Gap(AppSpacing.xs),
        GlassTextField(
          controller: controller,
          focusNode: focus,
          placeholder: placeholder,
          keyboardType: keyboardType,
          obscureText: obscureText,
          surfaceStyle: GlassSurfaceStyle.solid,
          shape: const LiquidRoundedSuperellipse(borderRadius: AppRadius.sm),
          onChanged: field.didChange,
        ),
        if (error != null) ...[
          const Gap(AppSpacing.xxs),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xxs),
            child: Text(error, style: errorStyle),
          ),
        ],
      ],
    );
  }
}
