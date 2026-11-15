import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:selfbox/core/forms/glass_reactive_text_field.dart';

import '../../support/app_widget_tester.dart';

void main() {
  testWidgets('multiline field binds line breaks and respects line limits', (
    tester,
  ) async {
    final form = FormGroup({'text': FormControl<String>(value: 'Existing')});
    addTearDown(form.dispose);
    await tester.pumpPage(
      Scaffold(
        body: ReactiveForm(
          formGroup: form,
          child: const GlassReactiveTextField<String>(
            formControlName: 'text',
            label: 'Prompt',
            minLines: 3,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
          ),
        ),
      ),
    );
    final editor = tester.widget<EditableText>(find.byType(EditableText));
    expect(editor.minLines, 3);
    expect(editor.maxLines, 8);
    await tester.enterText(find.byType(EditableText), 'One\nTwo');
    expect(form.control('text').value, 'One\nTwo');
  });
}
