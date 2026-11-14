import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/settings/presentation/providers/app_preferences_controller.dart';

import 'screenshot_fixtures.dart';

final onboardingFixtures = [
  for (final theme in Brightness.values)
    for (var step = 0; step < 5; step++)
      ScreenshotFixture(
        name: 'onboarding-${theme.name}-${step == 4 ? 'keyboard' : step}',
        location: '/onboarding',
        setUp: (tester, container) async {
          tester.platformDispatcher.platformBrightnessTestValue = theme;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await container
              .read(appPreferencesControllerProvider.notifier)
              .clear();
        },
        afterOpen: (tester) async {
          for (var index = 0; index < (step == 4 ? 1 : step); index++) {
            await tester.tap(find.byKey(const ValueKey('onboarding-next')));
            await tester.pumpAndSettle();
          }
          if (step == 4) {
            tester.view.physicalSize = const Size(840, 1950);
            tester.platformDispatcher.textScaleFactorTestValue = 1.5;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await tester.showKeyboard(find.byType(EditableText));
            tester.view.viewInsets = const FakeViewPadding(bottom: 750);
            await tester.pumpAndSettle();
          }
          final context = tester.element(find.byType(MaterialApp));
          final images = tester.widgetList<Image>(find.byType(Image)).toList();
          await tester.runAsync(() async {
            for (final image in images) {
              await precacheImage(image.image, context);
            }
          });
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      ),
];
