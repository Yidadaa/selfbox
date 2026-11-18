import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'screenshot_fixtures.dart';

final generalEffectsFixtures = [
  for (final brightness in Brightness.values)
    for (final picker in [false, true])
      ScreenshotFixture(
        name:
            'general-effects-${brightness.name}-${picker ? 'picker' : 'page'}',
        location: '/me/general',
        setUp: (tester, _) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await tester.pumpAndSettle();
        },
        afterOpen: (tester) async {
          if (picker) {
            await tester.tap(find.text(t.general.rendering));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
        },
      ),
];
