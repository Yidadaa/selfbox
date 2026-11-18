import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/forms/glass_reactive_text_field.dart';
import '../../../../gen/i18n/strings.g.dart';

class ProfilePromptField extends ConsumerWidget {
  const ProfilePromptField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ReactiveValueListenableBuilder<String>(
        formControlName: 'agentName',
        builder: (context, name, _) {
          final entered = name.value?.trim() ?? '';
          return GlassReactiveTextField<String>(
            formControlName: 'customPrompt',
            label: context.t.me.agentRequirements(
              agent: entered.isEmpty ? context.t.me.agentDefaultName : entered,
            ),
            placeholder: context.t.settings.customPromptHint,
            keyboardType: TextInputType.multiline,
            minLines: 4,
            maxLines: 4,
          );
        },
      );
}
