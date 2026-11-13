import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luthor/luthor.dart';

part '../../../../gen/features/settings/domain/models/ai_settings.freezed.dart';
part '../../../../gen/features/settings/domain/models/ai_settings.g.dart';

/// Wire protocol spoken by a provider endpoint.
enum ApiFormat {
  /// OpenAI-compatible `POST /chat/completions` (most third-party gateways).
  chatCompletions,

  /// OpenAI `POST /responses`.
  responses,

  /// Anthropic `POST /messages`.
  messages;

  String get defaultBaseUrl => switch (this) {
    ApiFormat.chatCompletions ||
    ApiFormat.responses => 'https://api.openai.com/v1',
    ApiFormat.messages => 'https://api.anthropic.com/v1',
  };
}

/// Mirrors the SDK's reasoning levels so settings stay SDK-independent.
enum ReasoningEffort { minimal, low, medium, high, xhigh }

@freezed
abstract class ProviderConfig with _$ProviderConfig {
  const factory ProviderConfig({
    required String id,
    required String name,
    required ApiFormat format,
    required String baseUrl,
    @Default(<String, String>{}) Map<String, String> headers,
  }) = _ProviderConfig;

  factory ProviderConfig.fromJson(Map<String, dynamic> json) =>
      _$ProviderConfigFromJson(json);
}

@freezed
abstract class ModelConfig with _$ModelConfig {
  const factory ModelConfig({
    required String providerId,
    required String modelId,
    @Default(false) bool enabled,

    /// Context budget for the request (history + tools + memory index).
    @Default(ModelConfig.defaultInputTokens) int maxInputTokens,
    @Default(ModelConfig.defaultOutputTokens) int maxOutputTokens,
    @Default(false) bool supportsImages,
    @Default(false) bool supportsReasoning,
    @Default(ReasoningEffort.medium) ReasoningEffort reasoningEffort,
  }) = _ModelConfig;

  const ModelConfig._();

  static const defaultInputTokens = 128000;
  static const defaultOutputTokens = 8192;

  factory ModelConfig.fromJson(Map<String, dynamic> json) =>
      _$ModelConfigFromJson(json);

  ModelRef get ref => ModelRef(providerId: providerId, modelId: modelId);
}

@freezed
abstract class ModelRef with _$ModelRef {
  const factory ModelRef({
    required String providerId,
    required String modelId,
  }) = _ModelRef;

  factory ModelRef.fromJson(Map<String, dynamic> json) =>
      _$ModelRefFromJson(json);
}

@freezed
abstract class AiSettings with _$AiSettings {
  const factory AiSettings({
    @Default(<ProviderConfig>[]) List<ProviderConfig> providers,
    @Default(<ModelConfig>[]) List<ModelConfig> models,
    ModelRef? activeModel,

    /// Most recent chat turns (from either side) sent as conversation history.
    @Default(AiSettings.defaultHistoryTurns) int historyTurns,
  }) = _AiSettings;

  const AiSettings._();

  static const defaultHistoryTurns = 20;
  static const minHistoryTurns = 0;
  static const maxHistoryTurns = 100;

  factory AiSettings.fromJson(Map<String, dynamic> json) =>
      _$AiSettingsFromJson(json);

  List<ModelConfig> modelsOf(String providerId) =>
      models.where((m) => m.providerId == providerId).toList();

  List<ModelConfig> get enabledModels =>
      models.where((m) => m.enabled).toList();

  /// The model AI mode will use: the chosen one if still enabled, otherwise
  /// the first enabled model.
  ModelConfig? get resolvedModel {
    final enabled = enabledModels;
    return enabled.where((m) => m.ref == activeModel).firstOrNull ??
        enabled.firstOrNull;
  }

  ProviderConfig? providerOf(String id) =>
      providers.where((p) => p.id == id).firstOrNull;
}

/// Validation rules shared by the settings forms and the repository.
abstract final class AiSettingsSchema {
  static const maxNameLength = 40;
  static const maxTokens = 10000000;

  static final providerName = l.string().min(1).max(maxNameLength).required();

  static final baseUrl = l
      .string()
      .url(allowedSchemes: const ['https', 'http'])
      .required();

  static final apiKey = l.string().min(1).required();

  static final inputTokens = l.int().min(1024).max(maxTokens).required();

  static final outputTokens = l.int().min(256).max(maxTokens).required();

  static final historyTurns = l.int()
      .min(AiSettings.minHistoryTurns)
      .max(AiSettings.maxHistoryTurns)
      .required();
}
