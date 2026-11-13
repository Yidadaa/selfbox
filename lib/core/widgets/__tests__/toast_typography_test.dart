import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/widgets/app_page_scaffold.dart';
import 'package:selfbox/core/widgets/app_toast.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('overlay toast inherits app typography in ${brightness.name}', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpApp();
      final context = tester.element(find.byType(AppPageScaffold).first);
      for (final type in GlassToastType.values) {
        AppToast.show(context, message: 'Saved', type: type);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        final richText = tester.widget<RichText>(
          find.descendant(
            of: find.text('Saved'),
            matching: find.byType(RichText),
          ),
        );
        final style = richText.text.style;
        expect(
          find.descendant(
            of: find.byType(GlassToast),
            matching: find.byType(HugeIcon),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(GlassToast),
            matching: find.byType(Icon),
          ),
          findsNothing,
        );
        expect(style?.decoration, TextDecoration.none);
        expect(
          style?.fontFamily,
          Theme.of(context).textTheme.bodyMedium?.fontFamily,
        );
        expect(style?.fontSize, 15);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(find.byType(GlassToast), findsNothing);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
