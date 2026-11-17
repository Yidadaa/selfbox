import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/data/chat_data_providers.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/features/settings/presentation/providers/app_preferences_controller.dart';

import '../../test/features/chat/presentation/pages/chat_page_test_support.dart';
import '../../test/support/app_widget_tester.dart';
import '../../test/support/fake_message_repository.dart';
import 'screenshot_fixtures.dart';

final pinnedMessageFixtures = [
  for (final theme in [AppThemeChoice.dark, AppThemeChoice.light])
    for (final mode in ['bubble', 'panel', 'keyboard', 'scrolled'])
      ScreenshotFixture(
        name: 'pins_${mode}_${theme.name}',
        location: '/chat',
        env: () => (
          paths: null,
          memory: null,
          settings: null,
          overrides: const [],
          messages: FakeMessageRepository(
            seed: [
              for (var id = 1; id <= 8; id++)
                Message(
                  id: id,
                  createdAt: kTestNow.subtract(Duration(minutes: 8 - id)),
                  author: id.isEven ? MessageAuthor.ai : MessageAuthor.me,
                  text: id.isEven
                      ? '可以先写下最重要的想法，再慢慢整理。\n\n**今天的小计划**\n\n- 留一点时间散步\n- 记录一个灵感'
                      : '把这段想法留在眼前，方便随时回看。',
                ),
            ],
          ),
        ),
        setUp: (tester, container) async {
          await container
              .read(appPreferencesControllerProvider.notifier)
              .setTheme(theme);
          final repo = container.read(messageRepositoryProvider);
          for (final id
              in mode == 'scrolled' ? [1, 2, 3, 4, 5, 6, 7] : [5, 6, 7]) {
            await repo.setPinned(id, pinned: true).run();
          }
          await tester.pumpAndSettle();
        },
        afterOpen: (tester) async {
          final images = tester.widgetList<Image>(find.byType(Image)).toList();
          final context = tester.element(find.byType(MaterialApp));
          await tester.runAsync(() async {
            for (final image in images) {
              await precacheImage(image.image, context);
            }
          });
          await tester.pumpAndSettle();
          if (mode == 'bubble') return;
          await tester.tap(find.byKey(const ValueKey('pinned-bubble')));
          await tester.pumpAndSettle();
          if (mode == 'keyboard') {
            await tester.tap(composerField());
            tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
            await tester.pumpAndSettle();
          }
          if (mode == 'scrolled') {
            await tester.drag(
              find.byKey(const PageStorageKey('pinned-message-list')),
              const Offset(0, 140),
            );
            await tester.pumpAndSettle();
          }
          expect(find.byKey(const ValueKey('pinned-panel')), findsOneWidget);
        },
      ),
];
