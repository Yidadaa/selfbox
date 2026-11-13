import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart' show Override;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../app.dart';
import '../../features/chat/data/chat_data_providers.dart';
import '../../features/chat/domain/repositories/language_model_factory.dart';
import '../../features/chat/domain/repositories/message_repository.dart';
import '../../features/memory/data/memory_data_providers.dart';
import '../../features/memory/domain/repositories/memory_repository.dart';
import '../../features/settings/data/settings_data_providers.dart';
import '../../features/settings/domain/models/app_preferences.dart';
import '../../features/settings/domain/repositories/account_repository.dart';
import '../../features/settings/domain/repositories/ai_settings_repository.dart';
import '../../features/settings/domain/repositories/app_preferences_repository.dart';
import '../../features/settings/presentation/providers/account_providers.dart';
import '../../features/settings/presentation/providers/app_preferences_controller.dart';
import '../../gen/i18n/strings.g.dart';
import '../storage/app_paths.dart';
import '../theme/app_scroll_behavior.dart';
import '../theme/app_theme.dart';
import '../time/clock.dart';
import 'fake_account_repository.dart';
import 'fake_ai_settings.dart';
import 'fake_app_preferences_repository.dart';
import 'fake_memory_repository.dart';
import 'fake_message_repository.dart';
import 'scripted_language_model.dart';
import 'temp_storage.dart';

/// Fixed "now" for every widget test: Thu 12 Nov 2026, 10:00.
final kTestNow = DateTime(2026, 11, 12, 10);

/// Storage-backed providers swapped for in-memory fakes. Tests override any
/// of these by passing their own instance.
List<Override> testAppOverrides({
  AccountRepository? account,
  MessageRepository? messages,
  MemoryRepository? memory,
  AiSettingsRepository? settings,
  AppPreferencesRepository? preferences,
  AppPreferences initialPreferences = const AppPreferences(),
  ModelCatalog? catalog,
  LanguageModelFactory? models,
  AppPaths? paths,
  DateTime? now,
}) => [
  accountRepositoryProvider.overrideWithValue(
    account ?? FakeAccountRepository(),
  ),
  appVersionProvider.overrideWith((ref) async => '0.3.0 (3)'),
  appPathsProvider.overrideWithValue(paths ?? createTempAppPaths()),
  messageRepositoryProvider.overrideWithValue(
    messages ?? FakeMessageRepository(),
  ),
  clockProvider.overrideWithValue(() => now ?? kTestNow),
  memoryRepositoryProvider.overrideWithValue(memory ?? FakeMemoryRepository()),
  aiSettingsRepositoryProvider.overrideWithValue(
    settings ?? FakeAiSettingsRepository(),
  ),
  appPreferencesRepositoryProvider.overrideWithValue(
    preferences ?? FakeAppPreferencesRepository(),
  ),
  initialAppPreferencesProvider.overrideWithValue(initialPreferences),
  modelCatalogProvider.overrideWithValue(catalog ?? FakeModelCatalog()),
  // Never reach a real endpoint from a test.
  languageModelFactoryProvider.overrideWithValue(
    models ?? FakeLanguageModelFactory(ScriptedLanguageModel(const [])),
  ),
];

/// iPhone 14-class logical viewport used by every widget test.
const kPhoneViewport = Size(390, 844);
const _devicePixelRatio = 3.0;

extension AppWidgetTester on WidgetTester {
  /// Fixed phone viewport with a notch and a home indicator, so layout and
  /// safe-area handling are exercised the same way on every machine.
  void usePhoneViewport() {
    view
      ..devicePixelRatio = _devicePixelRatio
      ..physicalSize = kPhoneViewport * _devicePixelRatio
      ..padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3)
      ..viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    addTearDown(view.reset);
  }

  /// Boots the real app shell (router, theme, i18n, glass scope).
  Future<ProviderContainer> pumpApp({
    AccountRepository? account,
    List<Override> overrides = const [],
    MessageRepository? messages,
    MemoryRepository? memory,
    AiSettingsRepository? settings,
    AppPreferencesRepository? preferences,
    AppPreferences initialPreferences = const AppPreferences(),
    ModelCatalog? catalog,
    LanguageModelFactory? models,
    AppPaths? paths,
    AppLocale locale = AppLocale.en,
    bool settle = true,
  }) async {
    usePhoneViewport();
    LocaleSettings.setLocaleSync(locale);
    // ProviderContainer.test is @visibleForTesting, which the analyzer does
    // not grant to lib/**/__tests__, so dispose explicitly instead.
    final container = ProviderContainer(
      overrides: [
        ...testAppOverrides(
          account: account,
          messages: messages,
          memory: memory,
          settings: settings,
          preferences: preferences,
          initialPreferences: initialPreferences,
          catalog: catalog,
          models: models,
          paths: paths,
        ),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    await pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TranslationProvider(
          child: LiquidGlassWidgets.wrap(
            brightnessResolver: Theme.maybeBrightnessOf,
            child: const SelfboxApp(),
          ),
        ),
      ),
    );
    // Pass settle: false when something animates forever (typing dots).
    settle ? await pumpAndSettle() : await pump(const Duration(seconds: 1));
    return container;
  }

  /// Renders a single page inside the design system without the router.
  Future<ProviderContainer> pumpPage(
    Widget page, {
    List<Override> overrides = const [],
    MessageRepository? messages,
    MemoryRepository? memory,
    AppLocale locale = AppLocale.en,
    Brightness brightness = Brightness.dark,
    bool settle = true,
  }) async {
    usePhoneViewport();
    LocaleSettings.setLocaleSync(locale);
    final container = ProviderContainer(
      overrides: [
        ...testAppOverrides(messages: messages, memory: memory),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    await pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TranslationProvider(
          child: LiquidGlassWidgets.wrap(
            brightnessResolver: Theme.maybeBrightnessOf,
            child: MaterialApp(
              theme: switch (brightness) {
                Brightness.dark => AppTheme.dark(),
                Brightness.light => AppTheme.light(),
              },
              scrollBehavior: const AppScrollBehavior(),
              home: page,
            ),
          ),
        ),
      ),
    );
    settle ? await pumpAndSettle() : await pump(const Duration(seconds: 1));
    return container;
  }
}
