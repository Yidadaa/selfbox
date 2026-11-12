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
import 'features/memory/data/memory_data_providers.dart';
import 'features/memory/data/repositories/file_memory_repository.dart';
import 'features/memory/domain/services/user_memory_service.dart';
import 'features/settings/data/repositories/local_account_repository.dart';
import 'features/settings/presentation/providers/account_providers.dart';
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

  LocaleSettings.useDeviceLocaleSync();
  // Application support (not documents) keeps app data out of the user's
  // visible files on desktop and in the backed-up sandbox on mobile.
  final paths = AppPaths(
    Directory('${(await getApplicationSupportDirectory()).path}/selfbox'),
  );
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
        memoryRepositoryProvider.overrideWithValue(memory),
      ],
      observers: [TalkerRiverpodObserver(talker: talker)],
      child: TranslationProvider(
        child: LiquidGlassWidgets.wrap(
          brightnessResolver: Theme.maybeBrightnessOf,
          child: const SelfboxApp(),
        ),
      ),
    ),
  );
}
