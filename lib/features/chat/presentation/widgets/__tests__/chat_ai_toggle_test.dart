import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_motion.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer_controls.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void main() {
  for (final locale in AppLocale.values) {
    testWidgets('AI label crossfades and resizes smoothly in ${locale.name}', (
      tester,
    ) async {
      final active = ValueNotifier(false);
      addTearDown(active.dispose);
      await tester.pumpPage(
        Align(
          alignment: Alignment.bottomRight,
          child: ValueListenableBuilder(
            valueListenable: active,
            builder: (_, enabled, _) => ChatAiToggle(
              active: enabled,
              onTap: () => active.value = !active.value,
            ),
          ),
        ),
        locale: locale,
      );
      final toggle = find.byType(ChatAiToggle);
      final before = tester.getRect(toggle);
      expect(find.text(t.chat.aiMode), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(t.chat.aiMode));
      await tester.pump();
      await tester.pump(AppMotion.aiLabelTransition ~/ 2);
      final middle = tester.getRect(toggle);
      expect(find.text(t.chat.aiMode), findsOneWidget);
      expect(find.text(t.chat.aiStandby), findsOneWidget);
      expect(middle.height, before.height);
      expect(middle.right, before.right);
      final fades = find.descendant(
        of: toggle,
        matching: find.byType(FadeTransition),
      );
      expect(
        tester
            .widgetList<FadeTransition>(fades)
            .any((fade) => fade.opacity.value > 0 && fade.opacity.value < 1),
        isTrue,
      );
      await tester.pumpAndSettle();
      final after = tester.getRect(toggle);
      expect(after.width, greaterThan(middle.width));
      expect(middle.width, greaterThan(before.width));
      expect(find.text(t.chat.aiMode), findsNothing);
      expect(find.text(t.chat.aiStandby), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(t.chat.aiMode));
      await tester.pump();
      await tester.pump(AppMotion.aiLabelTransition ~/ 2);
      expect(
        tester.getRect(toggle).width,
        inExclusiveRange(before.width, after.width),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(toggle), before);
      expect(tester.takeException(), isNull);
    });
  }
}
