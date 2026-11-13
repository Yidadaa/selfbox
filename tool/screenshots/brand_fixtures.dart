import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/widgets/app_artwork.dart';
import 'package:selfbox/core/widgets/app_page_scaffold.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'screenshot_fixtures.dart';

Future<void> _decodeArtwork(WidgetTester tester) async {
  final context = tester.element(find.byType(MaterialApp));
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  await tester.runAsync(() async {
    for (final image in images) {
      await precacheImage(image.image, context);
    }
  });
  await tester.pump();
}

final brandFixtures = [
  for (final theme in Brightness.values)
    for (final (width, keyboard) in [
      (280.0, false),
      (390.0, true),
      (280.0, true),
    ])
      ScreenshotFixture(
        name:
            'brand-welcome-${theme.name}-${width.toInt()}-${keyboard ? 'keyboard' : 'closed'}',
        location: '/chat',
        setUp: (tester, _) async {
          tester.platformDispatcher.platformBrightnessTestValue = theme;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          tester.view.physicalSize = Size(width * 3, 844 * 3);
        },
        afterOpen: (tester) async {
          if (keyboard) {
            await tester.tap(find.byType(EditableText));
            tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
          }
          await tester.pumpAndSettle();
          await _decodeArtwork(tester);
          expect(tester.takeException(), isNull);
        },
      ),
  for (final theme in Brightness.values)
    for (final (name, route) in [
      ('welcome', '/chat'),
      ('memory', '/memory'),
      ('search', '/chat/search'),
      ('about', '/me/about'),
      ('profile', '/me'),
      ('missing-file', '/memory/file?path=missing.md'),
      ('toast', '/me/about'),
    ])
      ScreenshotFixture(
        name: 'brand-$name-${theme.name}',
        location: route,
        setUp: (tester, _) async {
          tester.platformDispatcher.platformBrightnessTestValue = theme;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
        },
        afterOpen: (tester) async {
          await _decodeArtwork(tester);
          if (name == 'toast') {
            final context = tester.element(find.byType(AppPageScaffold).first);
            GlassToast.show(
              context,
              message: context.t.common.saved,
              duration: Duration.zero,
            );
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
        },
      ),
  ScreenshotFixture(
    name: 'brand-search-narrow',
    location: '/chat/search',
    afterOpen: (tester) async {
      tester.view.physicalSize = const Size(280 * 3, 600 * 3);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      await _decodeArtwork(tester);
      expect(find.byType(AppArtwork), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  ),
];
