import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'settings_test_support.dart';

void main() {
  testWidgets('settings list sections share the standard liquid surface', (
    tester,
  ) async {
    final container = await openSettingsPage(
      tester,
      '/me',
      settings: FakeAiSettingsRepository(
        settings: const AiSettings(
          providers: [testProvider],
          models: [
            ModelConfig(providerId: 'p1', modelId: 'gpt-x', enabled: true),
          ],
        ),
      ),
    );
    final router = container.read(appRouterProvider);
    expectLiquidSections(tester, 2);

    for (final (location, count) in [
      ('/me/general', 1),
      ('/me/providers', 2),
      ('/me/storage', 1),
      ('/me/provider?id=p1', 1),
      ('/me/model?provider=p1&model=gpt-x', 1),
    ]) {
      router.go(location);
      await tester.pumpAndSettle();
      expectLiquidSections(tester, count);
    }
  });

  testWidgets('provider and model form cards use liquid surfaces', (
    tester,
  ) async {
    final container = await openSettingsPage(
      tester,
      '/me/provider?id=p1',
      settings: FakeAiSettingsRepository(
        settings: const AiSettings(
          providers: [testProvider],
          models: [
            ModelConfig(providerId: 'p1', modelId: 'gpt-x', enabled: true),
          ],
        ),
      ),
    );
    expectLiquidFormCard(tester, t.settings.provider.name);

    container.read(appRouterProvider).go('/me/model?provider=p1&model=gpt-x');
    await tester.pumpAndSettle();
    expectLiquidFormCard(tester, t.settings.model.inputTokens);
  });

  testWidgets('provider cards retain liquid surfaces in dark mode', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await openSettingsPage(
      tester,
      '/me/provider?id=p1',
      settings: FakeAiSettingsRepository(
        settings: const AiSettings(
          providers: [testProvider],
          models: [
            ModelConfig(providerId: 'p1', modelId: 'gpt-x', enabled: true),
          ],
        ),
      ),
    );

    expectLiquidSections(tester, 1);
    expectLiquidFormCard(tester, t.settings.provider.name);
  });
}
