import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screenshot_fixtures.dart';

final composerKeyboardFixtures = [
  for (final brightness in Brightness.values)
    for (final opening in [true, false])
      for (final milliseconds in [0, 140, 280])
        ScreenshotFixture(
          name:
              'composer-keyboard-${brightness.name}-${opening ? 'open' : 'close'}-$milliseconds',
          location: '/chat',
          setUp: (tester, _) async {
            tester.platformDispatcher.platformBrightnessTestValue = brightness;
            addTearDown(
              tester.platformDispatcher.clearPlatformBrightnessTestValue,
            );
            await tester.pumpAndSettle();
          },
          afterOpen: (tester) async {
            final context = tester.element(find.byType(MaterialApp));
            final images = tester
                .widgetList<Image>(find.byType(Image))
                .toList();
            await tester.runAsync(() async {
              for (final image in images) {
                await precacheImage(image.image, context);
              }
            });
            await tester.tap(find.byType(EditableText));
            tester.view.viewInsets = const FakeViewPadding(bottom: 900);
            if (!opening) {
              await tester.pumpAndSettle();
              tester
                  .widget<EditableText>(find.byType(EditableText))
                  .focusNode
                  .unfocus();
              tester.view.viewInsets = const FakeViewPadding();
              await tester.pump();
            }
            await tester.pump();
            await tester.pump(Duration(milliseconds: milliseconds));
            expect(tester.takeException(), isNull);
          },
        ),
];
