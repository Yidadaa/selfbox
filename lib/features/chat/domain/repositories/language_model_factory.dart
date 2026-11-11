import 'package:ai_sdk_provider/ai_sdk_provider.dart';

import '../../../settings/domain/models/ai_settings.dart';

/// A ready-to-call model plus the cleanup for the HTTP client behind it.
typedef ModelHandle = ({LanguageModelV4 model, void Function() dispose});

/// Builds an SDK language model for a configured provider. The boundary to
/// the network, so tests can swap in scripted models.
abstract interface class LanguageModelFactory {
  ModelHandle create(ProviderConfig provider, String apiKey, String modelId);
}
