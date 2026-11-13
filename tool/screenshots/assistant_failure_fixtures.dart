import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/features/chat/domain/models/message.dart';
import 'package:selfbox/features/chat/presentation/providers/assistant_controller.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'screenshot_fixtures.dart';

final _question = Message(
  id: 1,
  createdAt: kTestNow,
  author: MessageAuthor.me,
  text: '帮我整理一下最近记录的待办。',
  askedAi: true,
);

class _FailedAssistant extends AssistantController {
  _FailedAssistant(this.failure);

  final AppFailure failure;

  @override
  AssistantState build() => AssistantState.failed(failure, _question);
}

ScreenshotEnv _environment(AppFailure failure) => (
  paths: null,
  messages: FakeMessageRepository(seed: [_question]),
  memory: null,
  settings: null,
  overrides: [
    assistantControllerProvider.overrideWith(() => _FailedAssistant(failure)),
  ],
);

final assistantFailureFixtures = [
  for (final brightness in Brightness.values)
    for (final narrow in [false, true])
      for (final (name, failure) in [
        ('setup', const AppFailure.validation(message: AppFailure.noModel)),
        ('network', const AppFailure.network(message: 'offline')),
      ])
        ScreenshotFixture(
          name:
              'assistant_failure_${name}_${brightness.name}_${narrow ? 'narrow' : 'phone'}',
          location: '/chat',
          env: () => _environment(failure),
          setUp: (tester, _) async {
            tester.platformDispatcher.platformBrightnessTestValue = brightness;
            addTearDown(
              tester.platformDispatcher.clearPlatformBrightnessTestValue,
            );
            if (narrow) {
              LocaleSettings.setLocaleSync(AppLocale.en);
              tester.view.physicalSize = const Size(280 * 3, 844 * 3);
              tester.platformDispatcher.textScaleFactorTestValue = 1.5;
              addTearDown(
                tester.platformDispatcher.clearTextScaleFactorTestValue,
              );
            }
            await tester.pumpAndSettle();
          },
        ),
];
