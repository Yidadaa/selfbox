import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../models/ai_settings.dart';

abstract interface class AiSettingsRepository {
  /// Current settings, re-emitted after every [save].
  Stream<AiSettings> watch();

  TaskEither<AppFailure, AiSettings> load();

  TaskEither<AppFailure, Unit> save(AiSettings settings);

  TaskEither<AppFailure, Option<String>> apiKey(String providerId);

  TaskEither<AppFailure, Unit> saveApiKey(String providerId, String apiKey);

  TaskEither<AppFailure, Unit> deleteApiKey(String providerId);
}

/// Lists the model ids a provider endpoint offers.
abstract interface class ModelCatalog {
  TaskEither<AppFailure, List<String>> fetch(
    ProviderConfig provider,
    String apiKey,
  );
}
