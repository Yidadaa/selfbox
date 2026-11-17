import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_scroll_controller.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/features/settings/presentation/providers/app_preferences_controller.dart';

import '../../test/support/app_widget_tester.dart';
import '../../test/support/fake_message_repository.dart';
import '../../test/support/temp_storage.dart';
import 'screenshot_fixtures.dart';

class _PhotoDraft extends ComposerController {
  @override
  ComposerState build() => const ComposerState(
    attachments: ['media/photo1.png', 'media/photo2.png', 'media/photo3.png'],
  );
}

ScreenshotEnv _photos() {
  final paths = createTempAppPaths();
  paths.media.createSync(recursive: true);
  for (var index = 1; index <= 3; index++) {
    File('tool/screenshots/assets/aurora.png')
        .copySync(p.join(paths.media.path, 'photo$index.png'));
  }
  return (
    paths: paths,
    memory: null,
    settings: null,
    overrides: [composerControllerProvider.overrideWith(_PhotoDraft.new)],
    messages: FakeMessageRepository(
      seed: [
        for (var id = 1; id <= 20; id++)
          Message(
            id: id,
            author: MessageAuthor.me,
            createdAt: kTestNow,
            text: '记录 $id：整理今天拍下的照片。',
          ),
      ],
    ),
  );
}

final composerPhotoFixtures = [
  for (final brightness in Brightness.values)
    ScreenshotFixture(
      name: 'composer_photos_${brightness.name}',
      location: '/chat',
      env: _photos,
      setUp: (tester, container) async {
        final preferences = container.read(
          appPreferencesControllerProvider.notifier,
        );
        await preferences.setTheme(
          brightness == Brightness.dark
              ? AppThemeChoice.dark
              : AppThemeChoice.light,
        );
        await preferences.setRenderQuality(AppRenderQuality.standard);
        await tester.pumpAndSettle();
        container.read(chatScrollControllerProvider).jumpTo(250);
        await tester.pumpAndSettle();
      },
    ),
];
