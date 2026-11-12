import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/router/app_dock_tabs.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_motion.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final locale in AppLocale.values) {
      testWidgets('unfocus restores tabs before keyboard moves in '
          '${brightness.name}/${locale.name}', (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpApp(locale: locale);
        final editable = find.byType(EditableText);
        final dock = find.byType(ChatComposer);
        await tester.enterText(editable, 'Keep this draft');
        final field = tester.widget<EditableText>(editable);
        field.controller.selection = const TextSelection.collapsed(offset: 7);
        tester.view.viewInsets = const FakeViewPadding(bottom: 900);
        await tester.pumpAndSettle();
        expect(find.byType(AppDockTabs), findsNothing);
        final editingHeight = tester.getSize(dock).height;

        field.focusNode.unfocus();
        // Focus changes notify after the current frame's microtasks.
        await tester.pump();
        await tester.pump();
        expect(find.byType(AppDockTabs), findsOneWidget);
        await tester.pump(AppMotion.fast ~/ 2);
        expect(tester.getSize(dock).height, greaterThan(editingHeight));

        for (final inset in [750.0, 450.0, 150.0]) {
          tester.view.viewInsets = FakeViewPadding(bottom: inset);
          await tester.pump();
          await tester.pump(AppMotion.fast);
          expect(find.byType(AppDockTabs), findsOneWidget);
          expect(
            tester.widget<EditableText>(editable).focusNode.hasFocus,
            isFalse,
          );
        }
        final restoredHeight = tester.getSize(dock).height;
        tester.view.viewInsets = const FakeViewPadding();
        await tester.pump();
        expect(tester.getSize(dock).height, restoredHeight);
        await tester.pumpAndSettle();
        expect(tester.getSize(dock).height, restoredHeight);
        final after = tester.widget<EditableText>(editable);
        expect(after.controller, same(field.controller));
        expect(after.controller.text, 'Keep this draft');
        expect(after.controller.selection.baseOffset, 7);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('refocus during dismissal restores the editing layout', (
    tester,
  ) async {
    await tester.pumpApp();
    final editable = find.byType(EditableText);
    await tester.enterText(editable, 'Resume typing');
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pumpAndSettle();
    final field = tester.widget<EditableText>(editable);
    field.focusNode.unfocus();
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppDockTabs), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 450);
    await tester.pump();
    field.focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(find.byType(AppDockTabs), findsNothing);
    expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isTrue);
    expect(
      tester.widget<EditableText>(editable).controller.text,
      'Resume typing',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'small screen budgets multiline input during keyboard dismissal',
    (tester) async {
      await tester.pumpApp();
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      final editable = find.byType(EditableText);
      await tester.enterText(editable, 'one\ntwo\nthree\nfour\nfive\nsix');
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      await tester.pumpAndSettle();
      tester.widget<EditableText>(editable).focusNode.unfocus();
      await tester.pump();
      await tester.pump(AppMotion.fast);
      expect(find.byType(AppDockTabs), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(ChatComposer)).dy,
        greaterThanOrEqualTo(47 + AppSizes.appBarHeight),
      );
      expect(
        tester.getBottomLeft(find.byType(ChatComposer)).dy,
        closeTo(640 - 300 - AppSpacing.xs, 1),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
