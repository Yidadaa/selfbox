import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../features/settings/domain/models/ai_settings.dart';
import '../../features/settings/domain/repositories/ai_settings_repository.dart';
import '../error/app_failure.dart';

/// In-memory [AiSettingsRepository] for widget/provider tests.
class FakeAiSettingsRepository implements AiSettingsRepository {
  FakeAiSettingsRepository({
    AiSettings settings = const AiSettings(),
    Map<String, String> apiKeys = const {},
  }) : current = settings,
       keys = {...apiKeys};

  AiSettings current;
  final Map<String, String> keys;
  final _changes = StreamController<AiSettings>.broadcast();

  @override
  Stream<AiSettings> watch() async* {
    yield current;
    yield* _changes.stream;
  }

  @override
  TaskEither<AppFailure, AiSettings> load() => TaskEither.right(current);

  @override
  TaskEither<AppFailure, Unit> save(AiSettings settings) {
    current = settings;
    _changes.add(settings);
    return TaskEither.right(unit);
  }

  @override
  TaskEither<AppFailure, Option<String>> apiKey(String providerId) =>
      TaskEither.right(Option.fromNullable(keys[providerId]));

  @override
  TaskEither<AppFailure, Unit> saveApiKey(String providerId, String apiKey) {
    keys[providerId] = apiKey.trim();
    return TaskEither.right(unit);
  }

  @override
  TaskEither<AppFailure, Unit> deleteApiKey(String providerId) {
    keys.remove(providerId);
    return TaskEither.right(unit);
  }
}

class FakeModelCatalog implements ModelCatalog {
  FakeModelCatalog([this.result = const Right(['model-a', 'model-b'])]);

  Either<AppFailure, List<String>> result;
  final calls = <({ProviderConfig provider, String apiKey})>[];

  @override
  TaskEither<AppFailure, List<String>> fetch(
    ProviderConfig provider,
    String apiKey,
  ) {
    calls.add((provider: provider, apiKey: apiKey));
    return TaskEither.fromEither(result);
  }
}
