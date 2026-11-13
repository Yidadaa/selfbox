import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'screenshot_fixtures.dart';

final agentProfileFixtures = [
  for (final brightness in Brightness.values)
    for (final locale in AppLocale.values)
      for (final sheet in [false, true])
        ScreenshotFixture(
          name:
              'agent-profile-${brightness.name}-${locale.name}-${sheet ? 'avatars' : 'form'}',
          location: '/me/profile',
          setUp: (tester, _) async {
            tester.platformDispatcher.platformBrightnessTestValue = brightness;
            addTearDown(
              tester.platformDispatcher.clearPlatformBrightnessTestValue,
            );
            LocaleSettings.setLocaleSync(locale);
            if (locale == AppLocale.en) {
              tester.view.physicalSize = const Size(280 * 3, 700 * 3);
              tester.platformDispatcher.textScaleFactorTestValue = 1.4;
              addTearDown(
                tester.platformDispatcher.clearTextScaleFactorTestValue,
              );
            }
            await tester.pumpAndSettle();
          },
          afterOpen: (tester) async {
            if (sheet) {
              await tester.tap(find.text(t.me.changeAvatar));
              await tester.pumpAndSettle();
            }
            final context = tester.element(find.byType(MaterialApp));
            final images = tester
                .widgetList<Image>(find.byType(Image))
                .toList();
            await tester.runAsync(() async {
              for (final image in images) {
                await precacheImage(image.image, context);
              }
            });
            await tester.pump();
            expect(tester.takeException(), isNull);
          },
        ),
];
