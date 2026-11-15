import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/features/settings/presentation/widgets/profile_prompt_field.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void main() {
  for (final locale in AppLocale.values) {
    testWidgets('four-line instructions follow the edited name in $locale', (
      tester,
    ) async {
      final form = FormGroup({
        'agentName': FormControl<String>(value: ''),
        'customPrompt': FormControl<String>(value: 'Existing instructions'),
      });
      addTearDown(form.dispose);
      await tester.pumpPage(
        ReactiveForm(formGroup: form, child: const ProfilePromptField()),
        locale: locale,
      );
      expect(
        find.text(t.me.agentRequirements(agent: t.me.agentDefaultName)),
        findsOneWidget,
      );
      final editor = tester.widget<EditableText>(find.byType(EditableText));
      expect(editor.minLines, 4);
      expect(editor.maxLines, 4);
      expect(editor.controller.text, 'Existing instructions');
      form.control('agentName').value = '  Momo  ';
      await tester.pumpAndSettle();
      expect(find.text(t.me.agentRequirements(agent: 'Momo')), findsOneWidget);
      expect(editor.controller.text, 'Existing instructions');
    });
  }
}
