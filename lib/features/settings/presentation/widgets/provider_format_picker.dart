import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/theme/app_glass_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../domain/models/ai_settings.dart';
import 'settings_labels.dart';

class ProviderFormatPicker extends StatelessWidget {
  const ProviderFormatPicker({
    required this.form,
    required this.formatControl,
    required this.baseUrlControl,
    super.key,
  });

  final FormGroup form;
  final String formatControl;
  final String baseUrlControl;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xxs),
          child: Text(
            context.t.settings.provider.format,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: glass.foregroundMuted),
          ),
        ),
        const Gap(AppSpacing.xs),
        ReactiveValueListenableBuilder<ApiFormat>(
          formControlName: formatControl,
          builder: (context, control, _) => GlassSegmentedControl(
            // Provider forms can contain several interactive glass controls.
            // Keep their transient indicator lens on the lightweight shader
            // path instead of the ios27 premium default.
            quality: GlassQuality.standard,
            selectedTextStyle: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w600),
            unselectedTextStyle: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: context.glass.foregroundMuted),
            selectedIndex: ApiFormat.values.indexOf(
              control.value ?? ApiFormat.chatCompletions,
            ),
            segments: [
              for (final format in ApiFormat.values)
                GlassSegment(label: format.label(context)),
            ],
            onSegmentSelected: (index) {
              final previous = control.value;
              final next = ApiFormat.values[index];
              control.value = next;
              // Preserve a custom URL when switching formats.
              final url = form.control(baseUrlControl);
              if (url.value == previous?.defaultBaseUrl) {
                url.value = next.defaultBaseUrl;
              }
            },
          ),
        ),
      ],
    );
  }
}
