import 'dart:async';

import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/scripted_language_model.dart';
import 'package:selfbox/features/settings/data/repositories/sdk_model_probe.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';

const _provider = ProviderConfig(
  id: 'p1',
  name: 'Gateway',
  format: ApiFormat.chatCompletions,
  baseUrl: 'https://gw.example.com/v1',
);
const _model = ModelConfig(providerId: 'p1', modelId: 'gpt-x', enabled: true);

void main() {
  test('sends a short generation request and disposes the model', () async {
    final model = ScriptedLanguageModel([
      [scriptedText('OK')],
    ]);
    final factory = FakeLanguageModelFactory(model);

    final result = await SdkModelProbe(factory)
        .test(_provider, 'secret', _model)
        .run();

    expect(result.isRight(), isTrue);
    expect(factory.created.single.modelId, 'gpt-x');
    expect(factory.created.single.apiKey, 'secret');
    expect(model.calls, hasLength(1));
    expect(factory.disposed, 1);
  });

  test('maps provider rejection and disposes the model', () async {
    final model = ScriptedLanguageModel(
      const [],
      error: const AiApiCallError('unauthorized', statusCode: 401),
    );
    final factory = FakeLanguageModelFactory(model);

    final result = await SdkModelProbe(factory)
        .test(_provider, 'secret', _model)
        .run();

    expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    expect((result.getLeft().toNullable() as NetworkFailure).statusCode, 401);
    expect(factory.disposed, 1);
  });

  test('times out a stalled model and disposes it', () async {
    final factory = FakeLanguageModelFactory(_StalledLanguageModel());
    final result = await SdkModelProbe(
      factory,
      timeout: const Duration(milliseconds: 20),
    ).test(_provider, 'secret', _model).run();

    expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    expect(factory.disposed, 1);
  });
}

class _StalledLanguageModel extends ScriptedLanguageModel {
  _StalledLanguageModel() : super(const []);

  @override
  Future<LanguageModelV4GenerateResult> doGenerate(
    LanguageModelV4CallOptions options,
  ) => Completer<LanguageModelV4GenerateResult>().future;
}
