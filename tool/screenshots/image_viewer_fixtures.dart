import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:selfbox/core/widgets/app_artwork.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';

import '../../test/support/app_widget_tester.dart';
import '../../test/support/fake_message_repository.dart';
import '../../test/support/temp_storage.dart';
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

ScreenshotEnv _discussions() => (
  paths: null,
  messages: FakeMessageRepository(
    seed: [
      Message(
        id: 1,
        createdAt: kTestNow,
        author: MessageAuthor.me,
        text: '今天的讨论记在这里',
      ),
      for (var id = 2; id <= 7; id++)
        Message(
          id: id,
          createdAt: kTestNow.add(Duration(minutes: id)),
          author: id.isEven ? MessageAuthor.me : MessageAuthor.ai,
          askedAi: id.isEven,
          text: '讨论 $id',
        ),
      Message(
        id: 8,
        createdAt: kTestNow.add(const Duration(minutes: 8)),
        author: MessageAuthor.me,
        text: '晚点再继续',
      ),
    ],
  ),
  memory: null,
  settings: null,
  overrides: const [],
);

final imageViewerFixtures = [
  for (final brightness in Brightness.values)
    for (final (name, route) in [
      ('image_viewer_photo', '/image?path=media%2Faurora.png'),
      ('image_viewer_bright', '/image?path=media%2Fbright.png'),
      ('image_stack', '/chat'),
      ('image_zoom', '/image?path=media%2Faurora.png'),
      ('search_neutral_icon', '/chat/search'),
      ('discussion_summary', '/chat'),
    ])
      ScreenshotFixture(
        name: '${name}_${brightness.name}',
        location: route,
        env: name == 'discussion_summary' ? _discussions : _photos,
        setUp: (tester, _) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await tester.pumpAndSettle();
        },
        afterOpen: (tester) async {
          if (name == 'discussion_summary') {
            await tester.runAsync(() async {
              final context = tester.element(find.byType(MaterialApp));
              for (final image in tester.widgetList<Image>(
                find.byType(Image),
              )) {
                await precacheImage(image.image, context);
              }
            });
            await tester.pumpAndSettle();
            expect(find.text('小懒收起了 6 条讨论'), findsOneWidget);
          }
          if (name == 'search_neutral_icon') {
            await tester.runAsync(() async {
              final context = tester.element(find.byType(AppArtwork));
              final image = tester.widget<Image>(
                find.descendant(
                  of: find.byType(AppArtwork),
                  matching: find.byType(Image),
                ),
              );
              await precacheImage(image.image, context);
              await Future<void>.delayed(const Duration(milliseconds: 100));
            });
            await tester.pumpAndSettle();
          }
          if (name == 'image_zoom') {
            final center = tester.getCenter(
              find.byType(InteractiveViewer).first,
            );
            await tester.tapAt(center);
            await tester.pump(const Duration(milliseconds: 80));
            await tester.tapAt(center);
            await tester.pumpAndSettle();
          }
        },
      ),
];
