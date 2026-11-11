import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart' show Override;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../app.dart';
import '../../features/chat/data/chat_data_providers.dart';
import '../../features/chat/domain/repositories/message_repository.dart';
import '../../features/memory/data/memory_data_providers.dart';
import '../../features/memory/domain/repositories/memory_repository.dart';
import '../../gen/i18n/strings.g.dart';
import '../storage/app_paths.dart';
import '../theme/app_scroll_behavior.dart';
import '../theme/app_theme.dart';
import '../time/clock.dart';
import 'fake_memory_repository.dart';
import 'fake_message_repository.dart';
import 'temp_storage.dart';

/// Fixed "now" for every widget test: Thu 12 Nov 2026, 10:00.
final kTestNow = DateTime(2026, 11, 12, 10);

/// Storage-backed providers swapped for in-memory fakes. Tests override any
/// of these by passing their own instance.
List<Override> testAppOverrides({
  MessageRepository? messages,
  MemoryRepository? memory,
  AppPaths? paths,
  DateTime? now,
}) => [
  appPathsProvider.overrideWithValue(paths ?? createTempAppPaths()),
  messageRepositoryProvider.overrideWithValue(
    messages ?? FakeMessageRepository(),
  ),
  clockProvider.overrideWithValue(() => now ?? kTestNow),
  memoryRepositoryProvider.overrideWithValue(memory ?? FakeMemoryRepository()),
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
    List<Override> overrides = const [],
    MessageRepository? messages,
    MemoryRepository? memory,
    AppPaths? paths,
    AppLocale locale = AppLocale.en,
  }) async {
    usePhoneViewport();
    LocaleSettings.setLocaleSync(locale);
    // ProviderContainer.test is @visibleForTesting, which the analyzer does
    // not grant to lib/**/__tests__, so dispose explicitly instead.
    final container = ProviderContainer(
      overrides: [
        ...testAppOverrides(messages: messages, memory: memory, paths: paths),
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
    await pumpAndSettle();
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
    await pumpAndSettle();
    return container;
  }
}
