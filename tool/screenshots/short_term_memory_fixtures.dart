import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'screenshot_fixtures.dart';

ScreenshotEnv _environment() => (
  paths: null,
  messages: null,
  memory: null,
  settings: FakeAiSettingsRepository(
    settings: const AiSettings(
      providers: [
        ProviderConfig(
          id: 'p',
          name: 'Gateway',
          format: ApiFormat.chatCompletions,
          baseUrl: 'https://example.com/v1',
        ),
      ],
      models: [ModelConfig(providerId: 'p', modelId: '128k', enabled: true)],
    ),
  ),
  overrides: const [],
);

final shortTermMemoryFixtures = [
  for (final brightness in Brightness.values)
    for (final narrow in [false, true])
      ScreenshotFixture(
        name:
            'short_term_memory_${brightness.name}_${narrow ? 'narrow' : 'phone'}',
        location: '/me/providers',
        env: _environment,
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
        afterOpen: (tester) async {
          await tester.tap(find.text(t.settings.shortTermMemory));
          await tester.pumpAndSettle();
        },
      ),
];
