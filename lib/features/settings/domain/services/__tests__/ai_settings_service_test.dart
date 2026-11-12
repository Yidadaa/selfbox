import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/domain/services/ai_settings_service.dart';

const _provider = ProviderConfig(
  id: 'p1',
  name: 'Gateway',
  format: ApiFormat.chatCompletions,
  baseUrl: 'https://gw.example.com/v1',
);

T _ok<T>(Either<AppFailure, T> result) =>
    result.getOrElse((f) => fail('expected success, got $f'));

void main() {
  late FakeAiSettingsRepository repo;
  late FakeModelCatalog catalog;
  late AiSettingsService service;

  setUp(() {
    repo = FakeAiSettingsRepository();
    catalog = FakeModelCatalog();
    service = AiSettingsService(repo, catalog);
  });

  group('AiSettingsService', () {
    test('reset barrier waits for a pending catalog merge', () async {
      repo.current = const AiSettings(providers: [_provider]);
      repo.keys['p1'] = 'key';
      final slow = _SlowCatalog();
      final tracked = AiSettingsService(repo, slow);
      final refresh = tracked.refreshModels('p1').run();
      var drained = false;
      final barrier = tracked.finishPending().then((_) => drained = true);
      await Future<void>.delayed(Duration.zero);
      expect(drained, false);
      slow.resultIds.complete(['model-a']);
      expect((await refresh).isRight(), true);
      await barrier;
      expect(repo.current.models.single.modelId, 'model-a');
    });
    test('saveProvider stores the config and the trimmed key', () async {
      _ok(await service.saveProvider(_provider, apiKey: ' sk ').run());

      expect(repo.current.providers, [_provider]);
      expect(repo.keys['p1'], 'sk');
    });

    test('a blank key keeps the existing secret', () async {
      repo.keys['p1'] = 'old';
      _ok(await service.saveProvider(_provider, apiKey: '   ').run());
      expect(repo.keys['p1'], 'old');
    });

    test('deleteProvider removes the secret too', () async {
      _ok(await service.saveProvider(_provider, apiKey: 'sk').run());
      _ok(await service.deleteProvider('p1').run());

      expect(repo.current.providers, isEmpty);
      expect(repo.keys, isEmpty);
    });

    test('refreshModels fetches with the stored key and merges', () async {
      _ok(await service.saveProvider(_provider, apiKey: 'sk').run());
      final settings = _ok(await service.refreshModels('p1').run());

      expect(catalog.calls.single.apiKey, 'sk');
      expect(catalog.calls.single.provider, _provider);
      expect(settings.modelsOf('p1').map((m) => m.modelId), [
        'model-a',
        'model-b',
      ]);
      expect(repo.current, settings);
    });

    test('refreshModels without a key fails before any request', () async {
      _ok(await service.saveProvider(_provider).run());
      final result = await service.refreshModels('p1').run();

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(catalog.calls, isEmpty);
    });

    test('refreshModels for an unknown provider fails', () async {
      final result = await service.refreshModels('nope').run();
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('a catalog failure leaves the settings unchanged', () async {
      _ok(await service.saveProvider(_provider, apiKey: 'sk').run());
      catalog.result = const Left(
        AppFailure.network(message: 'boom', statusCode: 500),
      );
      final before = repo.current;

      final result = await service.refreshModels('p1').run();
      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
      expect(repo.current, before);
    });

    test('enabling a model through saveModel selects it', () async {
      _ok(await service.saveProvider(_provider, apiKey: 'sk').run());
      _ok(await service.refreshModels('p1').run());

      final settings = _ok(
        await service
            .saveModel(
              const ModelConfig(
                providerId: 'p1',
                modelId: 'model-b',
                enabled: true,
              ),
            )
            .run(),
      );
      expect(settings.resolvedModel?.modelId, 'model-b');
    });

    test(
      'batch add enables selected models and remove makes one selectable again',
      () async {
        _ok(await service.saveProvider(_provider, apiKey: 'sk').run());
        _ok(await service.refreshModels('p1').run());

        final added = _ok(await service.addModels('p1', {'model-b'}).run());
        expect(added.enabledModels.map((m) => m.modelId), ['model-b']);
        expect(added.activeModel?.modelId, 'model-b');

        final removed = _ok(
          await service
              .removeModel(const ModelRef(providerId: 'p1', modelId: 'model-b'))
              .run(),
        );
        expect(removed.enabledModels, isEmpty);
        expect(removed.modelsOf('p1').map((m) => m.modelId), [
          'model-a',
          'model-b',
        ]);
        expect(removed.activeModel, isNull);
      },
    );

    test('setHistoryTurns persists the clamped value', () async {
      _ok(await service.setHistoryTurns(7).run());
      expect(repo.current.historyTurns, 7);
    });
  });
}

class _SlowCatalog extends FakeModelCatalog {
  final resultIds = Completer<List<String>>();
  @override
  TaskEither<AppFailure, List<String>> fetch(
    ProviderConfig provider,
    String apiKey,
  ) => TaskEither(() async => Right(await resultIds.future));
}
