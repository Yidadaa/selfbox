import 'package:ai_sdk_anthropic/ai_sdk_anthropic.dart';
import 'package:ai_sdk_openai/ai_sdk_openai.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../settings/domain/models/ai_settings.dart';
import '../../domain/repositories/language_model_factory.dart';

class SdkLanguageModelFactory implements LanguageModelFactory {
  const SdkLanguageModelFactory(this._dio);

  final DioFactory _dio;

  @override
  ModelHandle create(ProviderConfig provider, String apiKey, String modelId) {
    final client = _dio(
      baseUrl: provider.baseUrl,
      headers: _safeCustomHeaders(provider),
    );
    return switch (provider.format) {
      ApiFormat.chatCompletions => _openAi(
        provider,
        apiKey,
        client,
        (sdk) => sdk(modelId),
      ),
      ApiFormat.responses => _openAi(
        provider,
        apiKey,
        client,
        (sdk) => sdk.responses(modelId),
      ),
      ApiFormat.messages => _anthropic(provider, apiKey, client, modelId),
    };
  }

  static Map<String, String> _safeCustomHeaders(ProviderConfig provider) {
    final reserved = switch (provider.format) {
      ApiFormat.chatCompletions || ApiFormat.responses => {'authorization'},
      ApiFormat.messages => {'x-api-key', 'anthropic-version'},
    };
    return {
      for (final entry in provider.headers.entries)
        if (!reserved.contains(entry.key.toLowerCase())) entry.key: entry.value,
    };
  }

  static ModelHandle _openAi(
    ProviderConfig provider,
    String apiKey,
    Dio client,
    LanguageModelV4 Function(OpenAIProvider) pick,
  ) {
    final sdk = OpenAIProvider(
      apiKey: apiKey,
      baseUrl: provider.baseUrl,
      client: client,
    );
    return (model: pick(sdk), dispose: () => _dispose(sdk.dispose, client));
  }

  static ModelHandle _anthropic(
    ProviderConfig provider,
    String apiKey,
    Dio client,
    String modelId,
  ) {
    final sdk = AnthropicProvider(
      apiKey: apiKey,
      baseUrl: provider.baseUrl,
      client: client,
    );
    return (model: sdk(modelId), dispose: () => _dispose(sdk.dispose, client));
  }

  static void _dispose(void Function() disposeProvider, Dio client) {
    disposeProvider();
    client.close(force: true);
  }
}
