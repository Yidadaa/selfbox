import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/features/chat/presentation/widgets/chat_composer_attachment.dart';

import '../../../../support/app_widget_tester.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'attachment fades fixed glass in both directions: $brightness',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpApp();
        final external = find.byWidgetPredicate(
          (widget) => widget is ChatComposerAttachment && widget.external,
        );
        final surface = find.descendant(
          of: external,
          matching: find.byType(GlassContainer),
        );
        expect(surface, findsNothing);
        await tester.tap(find.byType(EditableText));
        tester.view.viewInsets = const FakeViewPadding(bottom: 900);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final entering = _expectFixedGlass(tester, surface);
        expect(entering, inExclusiveRange(0, 1));
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .unfocus();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 32));
        final leaving = _expectFixedGlass(tester, surface);
        expect(leaving, inExclusiveRange(0, entering));
        expect(
          tester
              .widget<IgnorePointer>(
                find
                    .descendant(
                      of: external,
                      matching: find.byType(IgnorePointer),
                    )
                    .first,
              )
              .ignoring,
          isTrue,
        );
        await tester.pumpAndSettle();
        expect(surface, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

double _expectFixedGlass(WidgetTester tester, Finder surface) {
  final glass = tester.widget<GlassContainer>(surface);
  final theme = tester.element(surface).glass;
  expect(glass.settings?.blur, theme.chromeBlur);
  expect(glass.settings?.glassColor, theme.chromeTint);
  return tester
      .widget<Opacity>(
        find.ancestor(of: surface, matching: find.byType(Opacity)).first,
      )
      .opacity;
}
