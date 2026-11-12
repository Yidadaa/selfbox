import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer_controls.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void main() {
  for (final locale in AppLocale.values) {
    for (final brightness in Brightness.values) {
      for (final keyboardOpen in [false, true]) {
        testWidgets('placeholder stays centered in ${locale.name}, '
            '${brightness.name}, keyboard=$keyboardOpen', (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await tester.pumpApp(locale: locale);
          if (keyboardOpen) {
            await tester.showKeyboard(find.byType(EditableText));
            tester.view.viewInsets = const FakeViewPadding(bottom: 900);
            await tester.pumpAndSettle();
          }

          for (final hint in [t.chat.inputHint, t.chat.aiInputHint]) {
            final editable = find.byType(EditableText);
            final placeholder = tester.getRect(find.text(hint));
            final input = tester.getRect(editable);
            final send = tester.getRect(find.byType(ChatSendButton));
            expect(placeholder.top, closeTo(input.top, 0.01));
            expect(placeholder.center.dy, closeTo(send.center.dy, 0.01));

            await tester.enterText(editable, hint);
            await tester.pumpAndSettle();
            expect(tester.getRect(editable), input);
            expect(tester.widget<EditableText>(editable).controller.text, hint);

            await tester.enterText(editable, '');
            await tester.pumpAndSettle();
            expect(tester.getRect(find.text(hint)), placeholder);
            if (hint == t.chat.inputHint) {
              await tester.tap(find.bySemanticsLabel(t.chat.aiMode));
              await tester.pumpAndSettle();
            }
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
