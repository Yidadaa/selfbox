import 'dart:async';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';

import '../../../../core/error/app_failure.dart';
import '../../../settings/domain/models/ai_settings.dart';
import 'agent_tools.dart';

/// Tool results carry text only, so viewed images follow the matching result
/// as a user turn. Step overrides do not persist, requiring this on each step.
GenerateTextPrepareStepResult? attachViewedImages(
  GenerateTextPrepareStepContext step,
  AgentTools tools,
) {
  if (tools.viewedImages.isEmpty) return null;
  final out = <LanguageModelV4Message>[];
  for (final message in step.messages) {
    out.add(message);
    if (message.role != LanguageModelV4Role.tool) continue;
    final images = [
      for (final part in message.content)
        if (part case LanguageModelV4ToolResultPart(:final toolCallId))
          if (tools.viewedImages[toolCallId] case final image?)
            LanguageModelV4ImagePart(
              image: DataContentBytes(image.bytes),
              mediaType: image.mediaType,
            ),
    ];
    if (images.isNotEmpty) {
      out.add(
        LanguageModelV4Message(role: LanguageModelV4Role.user, content: images),
      );
    }
  }
  return GenerateTextPrepareStepResult(messages: out);
}

LanguageModelV4Reasoning agentReasoning(ModelConfig model) {
  if (!model.supportsReasoning) return LanguageModelV4Reasoning.providerDefault;
  return switch (model.reasoningEffort) {
    ReasoningEffort.minimal => LanguageModelV4Reasoning.minimal,
    ReasoningEffort.low => LanguageModelV4Reasoning.low,
    ReasoningEffort.medium => LanguageModelV4Reasoning.medium,
    ReasoningEffort.high => LanguageModelV4Reasoning.high,
    ReasoningEffort.xhigh => LanguageModelV4Reasoning.xhigh,
  };
}

AppFailure agentFailure(Object error, StackTrace stack) => switch (error) {
  final AppFailure failure => failure,
  AiRetryError(:final lastError) => agentFailure(lastError, stack),
  AiApiCallError(:final message, :final statusCode) => AppFailure.network(
    message: message,
    statusCode: statusCode,
  ),
  AiOperationCancelledError() => const AppFailure.network(message: 'cancelled'),
  TimeoutException() => const AppFailure.network(message: 'timed out'),
  _ => AppFailure.unexpected(error: error, stackTrace: stack),
};
