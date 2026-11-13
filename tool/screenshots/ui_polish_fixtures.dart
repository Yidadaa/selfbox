import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/widgets/app_artwork.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'screenshot_fixtures.dart';

final uiPolishFixtures = [
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
