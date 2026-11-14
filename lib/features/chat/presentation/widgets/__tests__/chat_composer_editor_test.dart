import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer_editor.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('line padding follows text, width and scaling in $brightness', (
      tester,
    ) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      final geometry = ValueNotifier((width: 280.0, scale: 1.0));
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      addTearDown(geometry.dispose);
      await tester.pumpPage(
        ValueListenableBuilder(
          valueListenable: geometry,
          builder: (context, value, _) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(value.scale)),
            child: Center(
              child: SizedBox(
                width: value.width,
                child: ChatComposerEditor(
                  controller: controller,
                  focusNode: focus,
                  maxHeight: 200,
                ),
              ),
            ),
          ),
        ),
        brightness: brightness,
      );
      for (final text in [
        '',
        'hello',
        'first\nsecond',
        'first\n',
        '中文输入测试，保持自然换行与留白。',
        '👨‍👩‍👧‍👦 👋🏽 👨‍👩‍👧‍👦 👋🏽',
        'a long line that must wrap across the available width',
        'short',
        '',
      ]) {
        controller.text = text;
        for (final value in [
          (width: 280.0, scale: 1.0),
          (width: 120.0, scale: 1.0),
          (width: 120.0, scale: 2.0),
        ]) {
          geometry.value = value;
          await tester.pumpAndSettle();
          final field = tester.widget<CupertinoTextField>(
            find.byType(CupertinoTextField),
          );
          final painter = TextPainter(
            text: TextSpan(text: text, style: field.style),
            textDirection: TextDirection.ltr,
            textScaler: TextScaler.linear(value.scale),
            maxLines: 6,
          )..layout(maxWidth: value.width);
          final multiline =
              text.isNotEmpty && painter.computeLineMetrics().length > 1;
          painter.dispose();
          expect(
            field.padding,
            EdgeInsets.symmetric(
              vertical: multiline ? AppSpacing.composerVertical : 0,
            ),
            reason: '$text / $value',
          );
          expect(tester.takeException(), isNull);
        }
      }
    });
  }

  testWidgets(
    'multiline edits and selection changes preserve field configuration',
    (tester) async {
      final controller = TextEditingController(text: 'first\nsecond');
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await tester.pumpPage(
        Center(
          child: SizedBox(
            width: 200,
            child: ChatComposerEditor(
              controller: controller,
              focusNode: focus,
              maxHeight: 200,
            ),
          ),
        ),
      );
      final field = tester.widget<CupertinoTextField>(
        find.byType(CupertinoTextField),
      );
      for (final value in [
        const TextEditingValue(
          text: 'first\nsecond',
          selection: TextSelection.collapsed(offset: 2),
        ),
        const TextEditingValue(
          text: 'first\nsecond',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 0, end: 3),
        ),
        const TextEditingValue(text: 'first\nsecond extended'),
      ]) {
        controller.value = value;
        await tester.pump();
        expect(
          tester.widget<CupertinoTextField>(find.byType(CupertinoTextField)),
          same(field),
        );
      }
      controller.clear();
      await tester.pump();
      expect(
        tester
            .widget<CupertinoTextField>(find.byType(CupertinoTextField))
            .padding,
        EdgeInsets.zero,
      );
    },
  );
}
