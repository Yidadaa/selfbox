import 'package:ai_sdk_anthropic/ai_sdk_anthropic.dart';
import 'package:ai_sdk_openai/ai_sdk_openai.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';

import '../../../settings/domain/models/ai_settings.dart';
import '../../domain/repositories/language_model_factory.dart';

class SdkLanguageModelFactory implements LanguageModelFactory {
  const SdkLanguageModelFactory();

  @override
  ModelHandle create(
    ProviderConfig provider,
    String apiKey,
    String modelId,
  ) => switch (provider.format) {
    ApiFormat.chatCompletions => _openAi(provider, apiKey, (p) => p(modelId)),
    ApiFormat.responses => _openAi(
      provider,
      apiKey,
      (p) => p.responses(modelId),
    ),
    ApiFormat.messages => () {
      final sdk = AnthropicProvider(apiKey: apiKey, baseUrl: provider.baseUrl);
      return (model: sdk(modelId), dispose: sdk.dispose);
    }(),
  };

  static ModelHandle _openAi(
    ProviderConfig provider,
    String apiKey,
    LanguageModelV4 Function(OpenAIProvider) pick,
  ) {
    final sdk = OpenAIProvider(apiKey: apiKey, baseUrl: provider.baseUrl);
    return (model: pick(sdk), dispose: sdk.dispose);
  }
}
