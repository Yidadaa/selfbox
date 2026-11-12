import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../models/ai_settings.dart';
import '../repositories/ai_settings_repository.dart';
import '../repositories/model_probe.dart';

/// Resolves current settings and credentials before sending a test request.
class ModelTestService {
  const ModelTestService(this._settings, this._probe);

  final AiSettingsRepository _settings;
  final ModelProbe _probe;

  TaskEither<AppFailure, Unit> test(ModelRef ref) => _settings.load().flatMap((
    settings,
  ) {
    final model = settings.models
        .where((candidate) => candidate.ref == ref && candidate.enabled)
        .firstOrNull;
    final provider = settings.providerOf(ref.providerId);
    if (model == null || provider == null) {
      return TaskEither.left(
        const AppFailure.validation(message: AppFailure.noModel),
      );
    }
    return _settings
        .apiKey(provider.id)
        .flatMap(
          (key) => TaskEither.fromOption(
            key.filter((value) => value.trim().isNotEmpty),
            () =>
                const AppFailure.validation(message: AppFailure.missingApiKey),
          ).flatMap((apiKey) => _probe.test(provider, apiKey, model)),
        );
  });
}
