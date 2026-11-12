import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

import 'app.dart';
import 'core/database/app_store.dart';
import 'core/logger/talker_provider.dart';
import 'core/storage/app_paths.dart';
import 'features/chat/presentation/providers/assistant_controller.dart';
import 'features/memory/data/memory_data_providers.dart';
import 'features/memory/data/repositories/file_memory_repository.dart';
import 'features/memory/domain/services/user_memory_service.dart';
import 'features/settings/data/repositories/file_app_preferences_repository.dart';
import 'features/settings/data/repositories/local_account_repository.dart';
import 'features/settings/data/settings_data_providers.dart';
import 'features/settings/domain/models/app_preferences.dart';
import 'features/settings/presentation/providers/account_providers.dart';
import 'features/settings/presentation/providers/app_preferences_controller.dart';
import 'gen/i18n/strings.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Created before the ProviderScope so errors thrown during startup are
  // captured too; the same instance is injected into Riverpod below.
  final talker = TalkerFlutter.init();
  FlutterError.onError = (details) =>
      talker.handle(details.exception, details.stack, 'FlutterError');
  PlatformDispatcher.instance.onError = (error, stack) {
    talker.handle(error, stack, 'Uncaught platform error');
    return true;
  };

  // Application support (not documents) keeps app data out of the user's
  // visible files on desktop and in the backed-up sandbox on mobile.
  final paths = AppPaths(
    Directory('${(await getApplicationSupportDirectory()).path}/selfbox'),
  );
  final preferencesRepository = FileAppPreferencesRepository(paths);
  final preferences = (await preferencesRepository.load().run()).getOrElse((
    failure,
  ) {
    talker.error('App preferences load failed', failure);
    return const AppPreferences();
  });
  applyPreferredLanguage(preferences.language);
  final store = await openAppStore(paths);
  final account = LocalAccountRepository(store, paths);
  final memory = FileMemoryRepository(paths.memory);
  final profile = await account.load().run();
  final initialized = await TaskEither.fromEither(profile)
      .flatMap((value) => UserMemoryService(memory).ensure(value.nickname))
      .run();
  if (initialized.getLeft().toNullable() case final failure?) {
    talker.error('User memory initialization failed', failure);
  }
  await LiquidGlassWidgets.initialize();

  runApp(
    ProviderScope(
      overrides: [
        talkerProvider.overrideWithValue(talker),
        appPathsProvider.overrideWithValue(paths),
        appStoreProvider.overrideWithValue(store),
        accountRepositoryProvider.overrideWithValue(account),
        appPreferencesRepositoryProvider.overrideWithValue(
          preferencesRepository,
        ),
        initialAppPreferencesProvider.overrideWithValue(preferences),
        memoryRepositoryProvider.overrideWithValue(memory),
      ],
      observers: [appRiverpodObserver(talker)],
      child: TranslationProvider(
        child: LiquidGlassWidgets.wrap(
          brightnessResolver: Theme.maybeBrightnessOf,
          child: const SelfboxApp(),
        ),
      ),
    ),
  );
}

TalkerRiverpodObserver appRiverpodObserver(Talker talker) =>
    TalkerRiverpodObserver(
      talker: talker,
      settings: TalkerRiverpodLoggerSettings(
        providerFilter: (provider) => provider != assistantControllerProvider,
      ),
    );
