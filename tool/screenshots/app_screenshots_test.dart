// Design-review screenshots, not a gate. Renders real screens with real fonts
// into tool/screenshots/out/*.png:
//
//   ./.tools/flutter/bin/flutter test tool/screenshots --update-goldens
//
// The output directory is gitignored.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/storage/app_paths.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_bubble.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'assistant_failure_fixtures.dart';
import 'assistant_transition_fixtures.dart';
import 'brand_fixtures.dart';
import 'screenshot_fixtures.dart';
import 'short_term_memory_fixtures.dart';

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
  final cupertino = FontLoader('packages/cupertino_icons/CupertinoIcons');
  cupertino.addFont(
    rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
  );
  await cupertino.load();
  // Test text falls back to "Roboto"; map it to a CJK-capable system font.
  await _loadFont('Roboto', ['$winFonts/msyh.ttc', '$winFonts/segoeui.ttf']);
  // Unstyled text (e.g. GlassTabBar labels) falls back to the test font.
  await _loadFont('Ahem', ['$winFonts/msyh.ttc']);
  await _loadFont('FlutterTest', ['$winFonts/msyh.ttc']);
  await _loadFont('.SF Pro Text', ['$winFonts/msyh.ttc']);
  await _loadFont('CupertinoSystemText', ['$winFonts/msyh.ttc']);
  await _loadFont('CupertinoSystemDisplay', ['$winFonts/msyh.ttc']);
}

Future<void> _warmImages(AppPaths paths) async {
  if (!paths.media.existsSync()) return;
  for (final file in paths.media.listSync().whereType<File>()) {
    final done = Completer<void>();
    ResizeImage.resizeIfNeeded(kBubbleImageDecodeWidth, null, FileImage(file))
        .resolve(ImageConfiguration.empty)
        .addListener(
          ImageStreamListener(
            (_, _) => done.isCompleted ? null : done.complete(),
            onError: (_, _) => done.isCompleted ? null : done.complete(),
          ),
        );
    await done.future;
  }
}

void main() {
  setUpAll(_loadFonts);

  for (final shot in [
    ...screenshotFixtures,
    ...assistantTransitionFixtures,
    ...assistantFailureFixtures,
    ...shortTermMemoryFixtures,
    ...brandFixtures,
  ]) {
    for (final locale in [AppLocale.zhCn]) {
      testWidgets('screenshot ${shot.name}', (tester) async {
        final env = shot.env();
        // File images decode on real I/O, which never completes inside the
        // fake-async zone; warm the image cache before any widget asks.
        if (env.paths case final paths?) {
          await tester.runAsync(() => _warmImages(paths));
        }
        final container = await tester.pumpApp(
          locale: locale,
          paths: env.paths,
          messages: env.messages,
          memory: env.memory,
          settings: env.settings,
          overrides: env.overrides,
          settle: !shot.animated,
        );
        await shot.setUp?.call(tester, container);
        container.read(appRouterProvider).go(shot.location);
        shot.animated
            ? await tester.pump(const Duration(milliseconds: 600))
            : await tester.pumpAndSettle();
        await shot.afterOpen?.call(tester);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('out/${shot.name}.png'),
        );
      });
    }
  }
}
