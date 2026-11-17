import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_scroll_controller.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/widgets/message_quote_sheet.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';
import 'package:selfbox/features/settings/presentation/providers/account_providers.dart';
import 'package:selfbox/features/settings/presentation/providers/app_preferences_controller.dart';

import '../../test/support/app_widget_tester.dart';
import '../../test/support/fake_message_repository.dart';
import 'screenshot_fixtures.dart';

final chatActionFixtures = [
  for (final theme in [AppThemeChoice.dark, AppThemeChoice.light])
    for (final mode in ['actions', 'names'])
      ScreenshotFixture(
        name: 'chat104_${mode}_${theme.name}',
        location: '/chat',
        env: () => (
          paths: null,
          memory: null,
          settings: null,
          overrides: const [],
          messages: FakeMessageRepository(
            seed: [
              for (var id = 1; id <= 40; id++)
                Message(
                  id: id,
                  createdAt: kTestNow.subtract(Duration(minutes: 40 - id)),
                  author: id.isEven ? MessageAuthor.ai : MessageAuthor.me,
                  text: id.isEven ? '可以先记下这个想法，明天再慢慢完善。' : '今天的灵感：把重要的想法留在眼前。',
                ),
            ],
          ),
        ),
        setUp: (tester, container) async {
          await container
              .read(appPreferencesControllerProvider.notifier)
              .setTheme(theme);
          await container
              .read(accountRepositoryProvider)
              .save(const UserProfile(nickname: '阿青', agentName: '云朵'))
              .run();
          container.invalidate(userProfileProvider);
          final composer = container.read(composerControllerProvider.notifier);
          composer.toggleAiMode();
          for (final id in [1, 2]) {
            composer.quote(
              Message(
                id: id,
                createdAt: kTestNow,
                author: MessageAuthor.me,
                text: '',
              ),
            );
          }
          await tester.pumpAndSettle();
          container.read(chatScrollControllerProvider).jumpTo(250);
          await tester.pumpAndSettle();
        },
        afterOpen: (tester) async {
          if (mode == 'names') {
            unawaited(
              showQuoteEditor(tester.element(find.byType(EditableText))),
            );
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
        },
      ),
];
