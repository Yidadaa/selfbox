import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/domain/repositories/web_research_repository.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/chat/presentation/providers/message_link_preview.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';

import '../../test/support/app_widget_tester.dart';
import '../../test/support/fake_ai_settings.dart';
import '../../test/support/fake_message_repository.dart';
import 'screenshot_fixtures.dart';

final messageLinkFixtures = [
  for (final brightness in Brightness.values)
    ScreenshotFixture(
      name: 'profile_prompt_${brightness.name}',
      location: '/me/profile',
      env: () => (
        paths: null,
        memory: null,
        messages: null,
        overrides: const [],
        settings: FakeAiSettingsRepository(
          settings: const AiSettings(
            customPrompt: '请用简洁、自然的中文回答。\n\n涉及技术问题时保留关键细节，并给出具体例子。',
          ),
        ),
      ),
      setUp: (tester, _) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpAndSettle();
      },
      afterOpen: (tester) async {
        final context = tester.element(find.byType(MaterialApp));
        final images = tester.widgetList<Image>(find.byType(Image)).toList();
        await tester.runAsync(() async {
          for (final image in images) {
            await precacheImage(image.image, context);
          }
        });
        await tester.ensureVisible(find.byType(EditableText).last);
        await tester.pumpAndSettle();
      },
    ),
  for (final brightness in Brightness.values)
    ScreenshotFixture(
      name: 'message_links_${brightness.name}',
      location: '/chat',
      env: () => (
        paths: null,
        memory: null,
        settings: null,
        overrides: [
          messageLinkPreviewProvider('https://flutter.dev').overrideWith(
            (ref) async => const Right(
              WebPageContent(
                title: 'Flutter — 为每一块屏幕构建精彩体验',
                url: 'https://flutter.dev',
                text: '',
                description: '使用同一套代码，为移动设备、网页和桌面构建流畅而精美的应用。',
              ),
            ),
          ),
        ],
        messages: FakeMessageRepository(
          seed: [
            Message(
              id: 1,
              createdAt: kTestNow,
              author: MessageAuthor.me,
              text: '今天看到一篇不错的文章：https://dart.dev，晚一点读。',
            ),
            Message(
              id: 2,
              createdAt: kTestNow.add(const Duration(minutes: 1)),
              author: MessageAuthor.me,
              text: 'https://flutter.dev',
            ),
            Message(
              id: 3,
              createdAt: kTestNow.add(const Duration(minutes: 2)),
              author: MessageAuthor.me,
              text: '帮我看看这两个网站。',
              askedAi: true,
              quotedMessageIds: [1, 2],
            ),
          ],
        ),
      ),
      setUp: (tester, container) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        container.read(composerControllerProvider.notifier).toggleAiMode();
        await tester.pumpAndSettle();
      },
      afterOpen: (tester) async {
        final context = tester.element(find.byType(MaterialApp));
        final providers = tester
            .widgetList<Image>(find.byType(Image))
            .map((image) => image.image)
            .toList();
        await tester.runAsync(() async {
          for (final provider in providers) {
            await precacheImage(provider, context);
          }
        });
        await tester.pumpAndSettle();
      },
    ),
];
