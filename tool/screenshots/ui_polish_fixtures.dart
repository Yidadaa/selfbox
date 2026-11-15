import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/widgets/app_artwork.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/settings/presentation/providers/app_preferences_controller.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../test/support/fake_message_repository.dart';
import 'screenshot_fixtures.dart';

final uiPolishFixtures = [
  for (final theme in Brightness.values)
    for (final editing in [false, true])
      ScreenshotFixture(
        name: 'chat-layout-${theme.name}-${editing ? 'multiline' : 'bubbles'}',
        location: '/chat',
        env: () => (
          paths: null,
          memory: null,
          settings: null,
          overrides: const [],
          messages: FakeMessageRepository(
            seed: [
              Message(
                id: 1,
                createdAt: DateTime(2026, 11, 14),
                author: MessageAuthor.me,
                text: '你好',
                askedAi: true,
              ),
              Message(
                id: 2,
                createdAt: DateTime(2026, 11, 14),
                author: MessageAuthor.ai,
                text: '在呢～',
              ),
              Message(
                id: 3,
                createdAt: DateTime(2026, 11, 14),
                author: MessageAuthor.ai,
                text: '今天想聊些什么？我可以陪你整理思绪，也可以帮你记下灵光一现的想法。',
              ),
            ],
          ),
        ),
        setUp: (tester, container) async {
          tester.platformDispatcher.platformBrightnessTestValue = theme;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await container
              .read(appPreferencesControllerProvider.notifier)
              .setAnimationsEnabled(false);
          container.read(composerControllerProvider.notifier).toggleAiMode();
        },
        afterOpen: (tester) async {
          if (editing) {
            await tester.enterText(
              find.byType(EditableText),
              '明天要做的事\n整理这一周的笔记\n给小狗买点零食\n记得出门走走',
            );
            tester.view.viewInsets = const FakeViewPadding(bottom: 900);
          }
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      ),
  for (final theme in Brightness.values)
    for (final page in [
      'storage',
      'provider',
      'developer',
      'hidden-ai',
      'memory-percent',
    ])
      ScreenshotFixture(
        name: 'ui-polish-$page-${theme.name}',
        location: switch (page) {
          'developer' => '/me/about',
          'hidden-ai' => '/chat',
          'memory-percent' => '/me/providers',
          _ => '/me/$page',
        },
        env: () => (
          paths: null,
          memory: null,
          settings: null,
          overrides: const [],
          messages: FakeMessageRepository(
            seed: [
              Message(
                id: 1,
                createdAt: DateTime(2026, 11, 14),
                author: MessageAuthor.me,
                text: 'question',
                askedAi: true,
              ),
              Message(
                id: 2,
                createdAt: DateTime(2026, 11, 14),
                author: MessageAuthor.ai,
                text: 'answer',
              ),
            ],
          ),
        ),
        setUp: (tester, _) async {
          tester.platformDispatcher.platformBrightnessTestValue = theme;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
        },
        afterOpen: (tester) async {
          if (page == 'developer') {
            for (var i = 0; i < 5; i++) {
              await tester.tap(find.byType(AppArtwork));
              await tester.pump();
            }
            await tester.tap(find.bySemanticsLabel(t.common.close).first);
          }
          if (page == 'memory-percent') {
            await tester.tap(find.text(t.settings.shortTermMemory));
          }
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(MaterialApp));
          final images = tester.widgetList<Image>(find.byType(Image)).toList();
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
