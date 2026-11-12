import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/domain/repositories/model_probe.dart';
import 'package:selfbox/features/settings/domain/services/model_test_service.dart';

const _provider = ProviderConfig(
  id: 'p1',
  name: 'Gateway',
  format: ApiFormat.chatCompletions,
  baseUrl: 'https://gw.example.com/v1',
);
const _model = ModelConfig(providerId: 'p1', modelId: 'gpt-x', enabled: true);

class _Probe implements ModelProbe {
  final calls = <({ProviderConfig provider, String key, ModelConfig model})>[];
  Either<AppFailure, Unit> result = const Right(unit);

  @override
  TaskEither<AppFailure, Unit> test(
    ProviderConfig provider,
    String apiKey,
    ModelConfig model,
  ) {
    calls.add((provider: provider, key: apiKey, model: model));
    return TaskEither.fromEither(result);
  }
}

void main() {
  test(
    'uses the persisted provider, key and enabled model without saving',
    () async {
      final repo = FakeAiSettingsRepository(
        settings: const AiSettings(providers: [_provider], models: [_model]),
        apiKeys: {'p1': 'secret'},
      );
      final probe = _Probe();
      final before = repo.current;

      final result = await ModelTestService(repo, probe).test(_model.ref).run();

      expect(result.isRight(), isTrue);
      expect(probe.calls.single, (
        provider: _provider,
        key: 'secret',
        model: _model,
      ));
      expect(repo.current, before);
    },
  );

  test('rejects missing, disabled or orphaned models before probing', () async {
    final probe = _Probe();
    final cases = [
      const AiSettings(),
      const AiSettings(
        providers: [_provider],
        models: [ModelConfig(providerId: 'p1', modelId: 'gpt-x')],
      ),
      const AiSettings(models: [_model]),
    ];
    for (final settings in cases) {
      final repo = FakeAiSettingsRepository(
        settings: settings,
        apiKeys: {'p1': 'secret'},
      );
      final result = await ModelTestService(repo, probe).test(_model.ref).run();
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    }
    expect(probe.calls, isEmpty);
  });

  test('missing API key fails before probing', () async {
    final repo = FakeAiSettingsRepository(
      settings: const AiSettings(providers: [_provider], models: [_model]),
    );
    final probe = _Probe();
    final result = await ModelTestService(repo, probe).test(_model.ref).run();
    expect(
      result.getLeft().toNullable(),
      const AppFailure.validation(message: AppFailure.missingApiKey),
    );
    expect(probe.calls, isEmpty);
  });

  test('returns a provider failure without changing settings', () async {
    final repo = FakeAiSettingsRepository(
      settings: const AiSettings(providers: [_provider], models: [_model]),
      apiKeys: {'p1': 'secret'},
    );
    final probe = _Probe()
      ..result = const Left(
        AppFailure.network(message: 'unauthorized', statusCode: 401),
      );
    final before = repo.current;
    final result = await ModelTestService(repo, probe).test(_model.ref).run();
    expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    expect(repo.current, before);
  });
}
