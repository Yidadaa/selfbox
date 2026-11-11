import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../models/ai_settings.dart';
import '../repositories/ai_settings_repository.dart';
import 'ai_settings_edits.dart';

/// Read-modify-write operations on the persisted settings, plus the model
/// catalog round-trip that needs the stored API key.
class AiSettingsService {
  const AiSettingsService(this._repo, this._catalog);

  final AiSettingsRepository _repo;
  final ModelCatalog _catalog;

  TaskEither<AppFailure, AiSettings> _edit(
    AiSettings Function(AiSettings) change,
  ) => _repo.load().flatMap((current) {
    final next = change(current);
    return _repo.save(next).map((_) => next);
  });

  TaskEither<AppFailure, Option<String>> apiKey(String providerId) =>
      _repo.apiKey(providerId);

  /// Saves the provider; a non-blank [apiKey] replaces the stored one, a
  /// blank one keeps it (the form never shows the existing secret).
  TaskEither<AppFailure, AiSettings> saveProvider(
    ProviderConfig provider, {
    String apiKey = '',
  }) {
    final key = apiKey.trim();
    final storeKey = key.isEmpty
        ? TaskEither<AppFailure, Unit>.right(unit)
        : _repo.saveApiKey(provider.id, key);
    return storeKey.flatMap((_) => _edit((s) => s.upsertProvider(provider)));
  }

  TaskEither<AppFailure, AiSettings> deleteProvider(String providerId) => _repo
      .deleteApiKey(providerId)
      .flatMap((_) => _edit((s) => s.removeProvider(providerId)));

  /// Fetches the provider's model list and merges it into the settings.
  TaskEither<AppFailure, AiSettings> refreshModels(String providerId) => _repo
      .load()
      .flatMap(
        (settings) => TaskEither.fromOption(
          Option.fromNullable(settings.providerOf(providerId)),
          () => AppFailure.validation(message: 'unknown provider $providerId'),
        ),
      )
      .flatMap(
        (provider) => _repo
            .apiKey(providerId)
            .flatMap(
              (key) => TaskEither.fromOption(
                key.filter((k) => k.isNotEmpty),
                () => const AppFailure.validation(
                  message: AppFailure.missingApiKey,
                ),
              ),
            )
            .flatMap((key) => _catalog.fetch(provider, key)),
      )
      .flatMap((ids) => _edit((s) => s.mergeFetchedModels(providerId, ids)));

  TaskEither<AppFailure, AiSettings> saveModel(ModelConfig model) =>
      _edit((s) => s.upsertModel(model));

  TaskEither<AppFailure, AiSettings> selectModel(ModelRef ref) =>
      _edit((s) => s.selectModel(ref));

  TaskEither<AppFailure, AiSettings> setHistoryTurns(int turns) =>
      _edit((s) => s.withHistoryTurns(turns));
}
