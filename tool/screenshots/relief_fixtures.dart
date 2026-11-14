import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/widgets/app_modal_surface.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'screenshot_fixtures.dart';

final reliefFixtures = [
  for (final brightness in Brightness.values)
    for (final surface in ['dialog', 'actions', 'sheet'])
      ScreenshotFixture(
        name: 'relief-$surface-${brightness.name}',
        location: switch (surface) {
          'dialog' => '/me/storage',
          'actions' => '/me/components',
          _ => '/me/general',
        },
        setUp: (tester, _) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await tester.pumpAndSettle();
        },
        afterOpen: (tester) async {
          final target = find.text(switch (surface) {
            'dialog' => t.me.clearAll,
            'actions' => t.me.componentLibraryDialog,
            _ => t.general.theme,
          });
          await tester.scrollUntilVisible(target, 150);
          await tester.pumpAndSettle();
          await Scrollable.ensureVisible(
            tester.element(target),
            alignment: 0.5,
          );
          await tester.pumpAndSettle();
          await tester.tap(target);
          await tester.pumpAndSettle();
          expect(find.byType(AppModalSurface), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      ),
];
