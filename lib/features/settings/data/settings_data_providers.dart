import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/dio_factory.dart';
import '../../../core/storage/app_paths.dart';
import '../../../core/storage/secret_store.dart';
import '../domain/repositories/ai_settings_repository.dart';
import '../domain/repositories/app_preferences_repository.dart';
import 'repositories/file_ai_settings_repository.dart';
import 'repositories/file_app_preferences_repository.dart';
import 'repositories/http_model_catalog.dart';

part '../../../gen/features/settings/data/settings_data_providers.g.dart';

@Riverpod(keepAlive: true)
AppPreferencesRepository appPreferencesRepository(Ref ref) =>
    FileAppPreferencesRepository(ref.watch(appPathsProvider));

@Riverpod(keepAlive: true)
AiSettingsRepository aiSettingsRepository(Ref ref) => FileAiSettingsRepository(
  ref.watch(appPathsProvider),
  ref.watch(secretStoreProvider),
);

@Riverpod(keepAlive: true)
ModelCatalog modelCatalog(Ref ref) =>
    HttpModelCatalog(ref.watch(dioFactoryProvider));
