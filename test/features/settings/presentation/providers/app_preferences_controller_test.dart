import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/features/settings/presentation/providers/app_preferences_controller.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_app_preferences_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'developer unlock persists, fails atomically and resets on clear',
    () async {
      final repository = FakeAppPreferencesRepository();
      final container = ProviderContainer(
        overrides: testAppOverrides(preferences: repository),
      );
      addTearDown(container.dispose);
      final controller = container.read(
        appPreferencesControllerProvider.notifier,
      );
      repository.failure = const AppFailure.database(message: 'full');
      expect((await controller.unlockDeveloperTools()).isLeft(), isTrue);
      expect(
        container.read(appPreferencesControllerProvider).developerToolsUnlocked,
        isFalse,
      );
      repository.failure = null;
      expect((await controller.unlockDeveloperTools()).isRight(), isTrue);
      expect(repository.current.developerToolsUnlocked, isTrue);
      await controller.clear();
      expect(repository.current.developerToolsUnlocked, isFalse);
    },
  );

  test(
    'effect preferences persist and failed changes retain saved state',
    () async {
      final repository = FakeAppPreferencesRepository();
      final container = ProviderContainer(
        overrides: testAppOverrides(preferences: repository),
      );
      addTearDown(container.dispose);
      final controller = container.read(
        appPreferencesControllerProvider.notifier,
      );
      await controller.setRenderQuality(AppRenderQuality.premium);
      await controller.setAnimationsEnabled(false);
      final selected = container.read(appPreferencesControllerProvider);
      expect(selected.renderQuality, AppRenderQuality.premium);
      expect(selected.animationsEnabled, isFalse);
      expect(repository.current, selected);
      repository.failure = const AppFailure.database(message: 'full');
      expect(
        (await controller.setRenderQuality(AppRenderQuality.minimal)).isLeft(),
        isTrue,
      );
      expect((await controller.setAnimationsEnabled(true)).isLeft(), isTrue);
      expect(container.read(appPreferencesControllerProvider), selected);
    },
  );

  test('saves theme and language before exposing either change', () async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    final repository = FakeAppPreferencesRepository();
    final container = ProviderContainer(
      overrides: testAppOverrides(preferences: repository),
    );
    addTearDown(container.dispose);

    final controller = container.read(
      appPreferencesControllerProvider.notifier,
    );
    expect((await controller.setTheme(AppThemeChoice.dark)).isRight(), isTrue);
    expect(
      container.read(appPreferencesControllerProvider).theme,
      AppThemeChoice.dark,
    );
    expect(
      (await controller.setLanguage(AppLanguageChoice.zhCn)).isRight(),
      isTrue,
    );
    expect(
      container.read(appPreferencesControllerProvider).language,
      AppLanguageChoice.zhCn,
    );
    expect(LocaleSettings.currentLocale, AppLocale.zhCn);
    expect(
      repository.current,
      const AppPreferences(
        theme: AppThemeChoice.dark,
        language: AppLanguageChoice.zhCn,
      ),
    );
  });

  test('a failed save keeps the previous theme and language', () async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    final repository = FakeAppPreferencesRepository()
      ..failure = const AppFailure.database(message: 'full');
    final container = ProviderContainer(
      overrides: testAppOverrides(preferences: repository),
    );
    addTearDown(container.dispose);

    final controller = container.read(
      appPreferencesControllerProvider.notifier,
    );
    expect((await controller.setTheme(AppThemeChoice.dark)).isLeft(), isTrue);
    expect(
      (await controller.setLanguage(AppLanguageChoice.zhCn)).isLeft(),
      isTrue,
    );
    expect(
      container.read(appPreferencesControllerProvider),
      const AppPreferences(),
    );
    expect(LocaleSettings.currentLocale, AppLocale.en);
  });

  test('clearing preferences resets the active state', () async {
    final repository = FakeAppPreferencesRepository(
      current: const AppPreferences(
        theme: AppThemeChoice.dark,
        language: AppLanguageChoice.zhCn,
      ),
    );
    final container = ProviderContainer(
      overrides: testAppOverrides(
        preferences: repository,
        initialPreferences: repository.current,
      ),
    );
    addTearDown(container.dispose);

    expect(
      (await container.read(appPreferencesControllerProvider.notifier).clear())
          .isRight(),
      isTrue,
    );
    expect(
      container.read(appPreferencesControllerProvider),
      const AppPreferences(),
    );
    expect(repository.current, const AppPreferences());
  });
}
