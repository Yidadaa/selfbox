// Design-review screenshots, not a gate. Renders real screens with real fonts
// into tool/screenshots/out/*.png:
//
//   ./.tools/flutter/bin/flutter test tool/screenshots --update-goldens
//
// The output directory is gitignored.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'screenshot_fixtures.dart';

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await loader.load();
}

Future<void> _loadFonts() async {
  const winFonts = r'C:\Windows\Fonts';
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? '.tools/flutter';
  await _loadFont('MaterialIcons', [
    '$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  ]);
  // Test text falls back to "Roboto"; map it to a CJK-capable system font.
  await _loadFont('Roboto', ['$winFonts/msyh.ttc', '$winFonts/segoeui.ttf']);
  // Unstyled text (e.g. GlassTabBar labels) falls back to the test font.
  await _loadFont('Ahem', ['$winFonts/msyh.ttc']);
  await _loadFont('FlutterTest', ['$winFonts/msyh.ttc']);
  await _loadFont('.SF Pro Text', ['$winFonts/msyh.ttc']);
  await _loadFont('CupertinoSystemText', ['$winFonts/msyh.ttc']);
  await _loadFont('CupertinoSystemDisplay', ['$winFonts/msyh.ttc']);
}

void main() {
  setUpAll(_loadFonts);

  for (final shot in screenshotFixtures) {
    for (final locale in [AppLocale.zhCn]) {
      testWidgets('screenshot ${shot.name}', (tester) async {
        final container = await tester.pumpApp(
          locale: locale,
          overrides: shot.overrides(),
        );
        await shot.setUp?.call(tester, container);
        container.read(appRouterProvider).go(shot.location);
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('out/${shot.name}.png'),
        );
      });
    }
  }
}
