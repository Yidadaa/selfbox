import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/settings_data_providers.dart';
import '../../domain/models/ai_settings.dart';
import '../../domain/services/ai_settings_service.dart';

part '../../../../gen/features/settings/presentation/providers/settings_providers.g.dart';

@Riverpod(keepAlive: true)
AiSettingsService aiSettingsService(Ref ref) => AiSettingsService(
  ref.watch(aiSettingsRepositoryProvider),
  ref.watch(modelCatalogProvider),
);

@Riverpod(keepAlive: true)
Stream<AiSettings> aiSettings(Ref ref) =>
    ref.watch(aiSettingsRepositoryProvider).watch();

/// Whether a key is stored, for the "saved — leave blank" hint. Never exposes
/// the key itself to the UI.
@riverpod
Future<bool> hasApiKey(Ref ref, String providerId) async =>
    (await ref.watch(aiSettingsServiceProvider).apiKey(providerId).run()).match(
      (_) => false,
      (key) => key.isSome(),
    );
