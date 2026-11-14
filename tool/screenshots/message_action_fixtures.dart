import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/widgets/app_action_popover.dart';
import 'package:selfbox/core/widgets/app_page_button.dart';
import 'package:selfbox/core/widgets/app_popover_surface.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'screenshot_fixtures.dart';

final messageActionFixtures = [
  for (final brightness in Brightness.values)
    for (final (name, route) in [
      ('card', '/chat'),
      ('highlight', '/chat'),
      ('selection', '/chat'),
      ('profile', '/me/profile'),
      ('storage', '/me/storage'),
    ])
      ScreenshotFixture(
        name: 'message_actions_${name}_${brightness.name}',
        location: route,
        env: () => (
          paths: null,
          messages: FakeMessageRepository(
            seed: [
              Message(
                id: 1,
                createdAt: kTestNow,
                author: MessageAuthor.me,
                text: '周末去湖边走走，顺便给小懒拍几张照片。',
              ),
            ],
          ),
          memory: null,
          settings: null,
          overrides: const [],
        ),
        setUp: (tester, _) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await tester.pumpAndSettle();
        },
        afterOpen: (tester) async {
          switch (name) {
            case 'card' || 'highlight':
              final rect = tester.getRect(
                find.byKey(const ValueKey('message-surface')),
              );
              await tester.longPressAt(rect.topLeft + const Offset(24, 4));
              await tester.pumpAndSettle();
              expect(find.byType(AppActionPopover), findsOneWidget);
              if (name == 'highlight') {
                final finger = await tester.startGesture(
                  tester.getCenter(find.text(t.common.selectText)),
                );
                addTearDown(finger.cancel);
                await tester.pump();
                expect(
                  tester
                      .widget<AppPopoverSurface>(find.byType(AppPopoverSurface))
                      .highlightedIndex,
                  1,
                );
              }
            case 'selection':
              await tester.longPress(find.text('周末去湖边走走，顺便给小懒拍几张照片。'));
              await tester.pumpAndSettle();
              await tester.tap(find.text(t.common.selectText));
              await tester.pumpAndSettle();
              await tester.longPress(find.text('周末去湖边走走，顺便给小懒拍几张照片。'));
              await tester.pumpAndSettle();
              expect(find.byType(AppActionPopover), findsOneWidget);
            case 'profile' || 'storage':
              await tester.ensureVisible(find.byType(AppPageButton).last);
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
