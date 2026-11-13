import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/testing/temp_storage.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';

import 'screenshot_fixtures.dart';

ScreenshotEnv _photos() {
  final paths = createTempAppPaths();
  final directory = paths.media..createSync(recursive: true);
  final source = File('tool/screenshots/assets/aurora.png');
  source.copySync(p.join(directory.path, 'aurora.png'));
  File('assets/brand/state-reading.png')
      .copySync(p.join(directory.path, 'reading.png'));
  File(p.join(directory.path, 'bright.png')).writeAsBytesSync(
    img.encodePng(
      img.Image(width: 390, height: 844)..clear(img.ColorRgb8(255, 255, 255)),
    ),
  );
  return (
    paths: paths,
    messages: FakeMessageRepository(
      seed: [
        Message(
          id: 1,
          createdAt: kTestNow,
          author: MessageAuthor.me,
          text: '周末的相册',
          images: const [
            'media/aurora.png',
            'media/reading.png',
            'media/bright.png',
          ],
        ),
      ],
    ),
    memory: null,
    settings: null,
    overrides: const [],
  );
}

final imageViewerFixtures = [
  for (final brightness in Brightness.values)
    for (final (name, route) in [
      ('image_viewer_photo', '/image?path=media%2Faurora.png'),
      ('image_viewer_bright', '/image?path=media%2Fbright.png'),
      ('image_stack', '/chat'),
    ])
      ScreenshotFixture(
        name: '${name}_${brightness.name}',
        location: route,
        env: _photos,
        setUp: (tester, _) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await tester.pumpAndSettle();
        },
      ),
];
