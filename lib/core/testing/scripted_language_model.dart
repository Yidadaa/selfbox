import 'package:ai_sdk_dart/test.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';

import '../../features/chat/domain/repositories/language_model_factory.dart';
import '../../features/settings/domain/models/ai_settings.dart';

/// A model that answers each successive call with the next scripted step:
/// tool calls end the step with `toolCalls`, plain text with `stop`.
class ScriptedLanguageModel extends LanguageModelV4 {
  ScriptedLanguageModel(this.steps, {this.error});

  final List<List<LanguageModelV4ContentPart>> steps;

  /// Thrown from the first call instead of answering.
  final Object? error;

  final calls = <LanguageModelV4CallOptions>[];

  @override
  String get provider => 'scripted';

  @override
  String get modelId => 'scripted-model';

  MockLanguageModelV4 _next() {
    final step = calls.length - 1 < steps.length
        ? steps[calls.length - 1]
        : const <LanguageModelV4ContentPart>[];
    return MockLanguageModelV4(
      response: step,
      finishReason: step.any((p) => p is LanguageModelV4ToolCallPart)
          ? LanguageModelV4FinishReason.toolCalls
          : LanguageModelV4FinishReason.stop,
      doStreamError: calls.length == 1 ? error : null,
      doGenerateError: calls.length == 1 ? error : null,
    );
  }

  @override
  Future<LanguageModelV4GenerateResult> doGenerate(
    LanguageModelV4CallOptions options,
  ) {
    calls.add(options);
    return _next().doGenerate(options);
  }

  @override
  Future<LanguageModelV4StreamResult> doStream(
    LanguageModelV4CallOptions options,
  ) {
    calls.add(options);
    return _next().doStream(options);
  }
}

LanguageModelV4ToolCallPart scriptedToolCall(
  String toolName,
  Map<String, Object?> input, {
  String? id,
}) => LanguageModelV4ToolCallPart(
  toolCallId: id ?? 'call_${toolName}_${input.hashCode}',
  toolName: toolName,
  input: input,
);

LanguageModelV4TextPart scriptedText(String text) =>
    LanguageModelV4TextPart(text: text);

LanguageModelV4ReasoningPart scriptedReasoning(String text) =>
    LanguageModelV4ReasoningPart(text: text);

/// Hands out [model] and records what it was asked to build.
class FakeLanguageModelFactory implements LanguageModelFactory {
  FakeLanguageModelFactory(this.model);

  LanguageModelV4 model;
  final created =
      <({ProviderConfig provider, String apiKey, String modelId})>[];
  var disposed = 0;

  @override
  ModelHandle create(ProviderConfig provider, String apiKey, String modelId) {
    created.add((provider: provider, apiKey: apiKey, modelId: modelId));
    return (model: model, dispose: () => disposed++);
  }
}
