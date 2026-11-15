import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/forms/glass_reactive_text_field.dart';
import '../../../../core/theme/app_effects.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../gen/i18n/strings.g.dart';
import 'provider_format_picker.dart';

class ProviderCredentialsCard extends StatelessWidget {
  const ProviderCredentialsCard({
    required this.form,
    required this.keyStored,
    super.key,
  });

  static const name = 'name';
  static const format = 'format';
  static const baseUrl = 'baseUrl';
  static const apiKey = 'apiKey';
  final FormGroup form;
  final bool keyStored;

  @override
  Widget build(BuildContext context) {
    final labels = context.t.settings.provider;
    return GlassContainer.card(
      surfaceStyle: GlassSurfaceStyle.solid,
      shape: LiquidRoundedSuperellipse(
        borderRadius: AppRadius.lg,
        side: AppEffects.solidBorderOf(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassReactiveTextField<String>(
            formControlName: name,
            label: labels.name,
          ),
          const Gap(AppSpacing.md),
          ProviderFormatPicker(
            form: form,
            formatControl: format,
            baseUrlControl: baseUrl,
          ),
          const Gap(AppSpacing.md),
          GlassReactiveTextField<String>(
            formControlName: baseUrl,
            label: labels.baseUrl,
            keyboardType: TextInputType.url,
          ),
          const Gap(AppSpacing.md),
          GlassReactiveTextField<String>(
            formControlName: apiKey,
            label: labels.apiKey,
            placeholder: keyStored ? labels.apiKeyKept : null,
            obscureText: true,
          ),
        ],
      ),
    );
  }
}
