import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/widgets/app_page_scaffold.dart';
import 'package:selfbox/core/widgets/app_toast.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/chat_scroll_controller.dart';
import 'package:selfbox/features/chat/presentation/providers/composer_controller.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/features/settings/presentation/providers/app_preferences_controller.dart';

import '../../test/support/app_widget_tester.dart';
import '../../test/support/fake_ai_settings.dart';
import '../../test/support/fake_message_repository.dart';
import 'screenshot_fixtures.dart';

final task88Fixtures = [
  for (final brightness in Brightness.values)
    for (final mode in [
      'chat',
      'ai',
      'provider',
      'toast',
      'memory',
      'settings',
    ])
      ScreenshotFixture(
        name: 'task88_${mode}_${brightness.name}',
        location: switch (mode) {
          'provider' => '/me/provider?id=p1',
          'memory' => '/memory',
          'settings' => '/me',
          _ => '/chat',
        },
        env: () => (
          paths: null,
          memory: null,
          overrides: const [],
          messages: FakeMessageRepository(
            seed: [
              for (var id = 1; id <= 30; id++)
                Message(
                  id: id,
                  author: MessageAuthor.me,
                  createdAt: kTestNow,
                  text: '第 $id 条记录：留一点时间整理今天的想法。',
                ),
            ],
          ),
          settings: FakeAiSettingsRepository(
            settings: const AiSettings(
              providers: [
                ProviderConfig(
                  id: 'p1',
                  name: 'OpenAI',
                  format: ApiFormat.chatCompletions,
                  baseUrl: 'https://api.openai.com/v1',
                ),
              ],
              models: [
                ModelConfig(
                  providerId: 'p1',
                  modelId: 'gpt-4.1',
                  enabled: true,
                ),
              ],
            ),
          ),
        ),
        setUp: (tester, container) async {
          final preferences = container.read(
            appPreferencesControllerProvider.notifier,
          );
          await preferences.setTheme(
            brightness == Brightness.dark
                ? AppThemeChoice.dark
                : AppThemeChoice.light,
          );
          await preferences.setRenderQuality(AppRenderQuality.minimal);
          if (mode == 'ai') {
            container.read(composerControllerProvider.notifier).toggleAiMode();
          }
          await tester.pumpAndSettle();
          if (mode == 'chat') {
            container.read(chatScrollControllerProvider).jumpTo(250);
            await tester.pumpAndSettle();
          }
        },
        afterOpen: (tester) async {
          if (mode == 'toast') {
            AppToast.show(
              tester.element(find.byType(AppPageScaffold).first),
              message: '已保存',
            );
            await tester.pumpAndSettle();
          }
        },
      ),
];
