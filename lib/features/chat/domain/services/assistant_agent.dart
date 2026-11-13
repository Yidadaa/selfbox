import 'dart:async';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../../../memory/domain/models/memory.dart';
import '../../../memory/domain/repositories/memory_repository.dart';
import '../../../settings/domain/models/ai_settings.dart';
import '../../../settings/domain/repositories/account_repository.dart';
import '../../../settings/domain/repositories/ai_settings_repository.dart';
import '../models/agent_activity.dart';
import '../models/message.dart';
import '../repositories/language_model_factory.dart';
import '../repositories/message_repository.dart';
import 'agent_prompt.dart';
import 'agent_tools.dart';
import 'vercel_gateway_options.dart';

enum AgentToolPhase { started, succeeded, failed }

typedef AgentToolTrace = void Function(String toolName, AgentToolPhase phase);

/// Runs one AI-mode turn: gathers history and memory, lets the model call
/// tools for several steps, and returns the final answer text.
class AssistantAgent {
  const AssistantAgent({
    required this.settings,
    required this.account,
    required this.messages,
    required this.memory,
    required this.readImage,
    required this.models,
    required this.clock,
    required this.languageTag,
  });

  final AiSettingsRepository settings;
  final AccountRepository account;
  final MessageRepository messages;
  final MemoryRepository memory;
  final ImageReader readImage;
  final LanguageModelFactory models;
  final DateTime Function() clock;
  final String Function() languageTag;

  /// Upper bound on model round-trips per question.
  static const maxSteps = 16;
  static const timeout = Duration(minutes: 3);

  static const noModel = AppFailure.noModel;

  TaskEither<AppFailure, String> answer(
    Message question, {
    required void Function(AgentActivity) onActivity,
    AgentToolTrace? onToolEvent,
    CancellationToken? cancel,
  }) => account.load().flatMap(
    (profile) => settings
        .load()
        .flatMap(_resolveModel)
        .flatMap(
          (setup) => messages
              .latest(setup.settings.historyTurns + 1)
              .flatMap(
                (recent) => memory.list().flatMap(
                  (index) => _run(
                    setup: setup,
                    question: question,
                    recent: recent,
                    index: index,
                    userName: profile.nickname.trim(),
                    onActivity: onActivity,
                    onToolEvent: onToolEvent,
                    cancel: cancel,
                  ),
                ),
              ),
        ),
  );

  TaskEither<AppFailure, _Setup> _resolveModel(AiSettings s) {
    final model = s.resolvedModel;
    final provider = model == null ? null : s.providerOf(model.providerId);
    if (model == null || provider == null) {
      return TaskEither.left(const AppFailure.validation(message: noModel));
    }
    return settings
        .apiKey(provider.id)
        .flatMap(
          (key) => TaskEither.fromOption(
            key.filter((k) => k.isNotEmpty),
            () =>
                const AppFailure.validation(message: AppFailure.missingApiKey),
          ),
        )
        .map(
          (key) => _Setup(
            settings: s,
            model: model,
            provider: provider,
            apiKey: key,
          ),
        );
  }

  TaskEither<AppFailure, String> _run({
    required _Setup setup,
    required Message question,
    required List<Message> recent,
    required List<MemoryEntry> index,
    required String userName,
    required void Function(AgentActivity) onActivity,
    required AgentToolTrace? onToolEvent,
    required CancellationToken? cancel,
  }) => TaskEither.tryCatch(() async {
    final model = setup.model;
    final tools = AgentTools(
      messages: messages,
      memory: memory,
      readImage: readImage,
      canViewImages: model.supportsImages,
      onResult: (name, succeeded) => onToolEvent?.call(
        name,
        succeeded ? AgentToolPhase.succeeded : AgentToolPhase.failed,
      ),
    );
    final instructions = buildAgentInstructions(
      now: clock(),
      memory: index,
      canViewImages: model.supportsImages,
      userName: userName,
      languageTag: languageTag(),
    );
    // The question is normally the newest note; keep it even if it is not.
    final notes = recent.any((m) => m.id == question.id)
        ? recent
        : [question, ...recent];
    final history = buildAgentHistory(
      fitHistory(
        notes,
        budget: model.maxInputTokens - model.maxOutputTokens,
        instructions: instructions,
      ),
    );

    final handle = models.create(setup.provider, setup.apiKey, model.modelId);
    try {
      onActivity(const AgentActivity.thinking());
      final result = await streamText<Object?>(
        model: handle.model,
        instructions: instructions,
        messages: history,
        tools: tools.build(),
        maxSteps: maxSteps,
        maxOutputTokens: model.maxOutputTokens,
        reasoning: _reasoning(model),
        providerOptions: vercelGatewayProviderOptions(
          provider: setup.provider,
          model: model,
        ),
        abortSignal: cancel,
        timeout: const TimeoutConfiguration(total: timeout),
        prepareStep: (step) => _attachViewedImages(step, tools),
      );

      Object? streamError;
      var reasoningText = '';
      var segment = 0;
      var typingStarted = false;
      var startedStep = false;
      await for (final event in result.stream) {
        switch (event) {
          case StreamTextStartStepEvent():
            reasoningText = '';
            typingStarted = false;
            if (startedStep) {
              segment++;
              onActivity(AgentActivity.thinking(segment: segment));
            }
            startedStep = true;
          case StreamTextToolInputStartEvent(:final toolName):
            reasoningText = '';
            typingStarted = false;
            onToolEvent?.call(toolName, AgentToolPhase.started);
            final kind = AgentToolKind.ofTool(toolName);
            if (kind != null) onActivity(AgentActivity.tool(kind));
          case StreamTextToolErrorEvent(:final toolName):
            onToolEvent?.call(toolName, AgentToolPhase.failed);
          case StreamTextReasoningDeltaEvent(:final delta):
            final previous = reasoningText;
            reasoningText += delta;
            if (reasoningText.length > _maxReasoningCodeUnits) {
              reasoningText = _reasoningTail(reasoningText);
              segment++;
            }
            if (reasoningText.trim().isNotEmpty && reasoningText != previous) {
              onActivity(
                AgentActivity.thinking(text: reasoningText, segment: segment),
              );
            }
          case StreamTextTextDeltaEvent(:final delta):
            if (!typingStarted && delta.trim().isNotEmpty) {
              typingStarted = true;
              onActivity(const AgentActivity.typing());
            }
          case StreamTextErrorEvent(:final error):
            streamError = error;
          default:
            break;
        }
      }
      if (streamError != null) throw streamError;
      final text = (await result.text).trim();
      if (text.isEmpty) {
        throw const AppFailure.network(message: 'empty reply');
      }
      return text;
    } finally {
      handle.dispose();
    }
  }, _toFailure);

  static const _maxReasoningCodeUnits = 8192;
  static const _retainedReasoningCodeUnits = 4096;

  static String _reasoningTail(String text) {
    var start = text.length - _retainedReasoningCodeUnits;
    // A trim must not leave a broken UTF-16 surrogate at the stream boundary.
    if (text.codeUnitAt(start) >= 0xDC00 && text.codeUnitAt(start) <= 0xDFFF) {
      start++;
    }
    return text.substring(start);
  }

  /// Tool results carry text only, so images fetched by `view_image` are
  /// attached as a user turn right after the matching result. Re-derived on
  /// every step because step overrides do not persist.
  static GenerateTextPrepareStepResult? _attachViewedImages(
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
          LanguageModelV4Message(
            role: LanguageModelV4Role.user,
            content: images,
          ),
        );
      }
    }
    return GenerateTextPrepareStepResult(messages: out);
  }

  static LanguageModelV4Reasoning _reasoning(ModelConfig model) {
    if (!model.supportsReasoning) {
      return LanguageModelV4Reasoning.providerDefault;
    }
    return switch (model.reasoningEffort) {
      ReasoningEffort.minimal => LanguageModelV4Reasoning.minimal,
      ReasoningEffort.low => LanguageModelV4Reasoning.low,
      ReasoningEffort.medium => LanguageModelV4Reasoning.medium,
      ReasoningEffort.high => LanguageModelV4Reasoning.high,
      ReasoningEffort.xhigh => LanguageModelV4Reasoning.xhigh,
    };
  }

  static AppFailure _toFailure(Object error, StackTrace stack) =>
      switch (error) {
        final AppFailure failure => failure,
        AiRetryError(:final lastError) => _toFailure(lastError, stack),
        AiApiCallError(:final message, :final statusCode) => AppFailure.network(
          message: message,
          statusCode: statusCode,
        ),
        AiOperationCancelledError() => const AppFailure.network(
          message: 'cancelled',
        ),
        TimeoutException() => const AppFailure.network(message: 'timed out'),
        _ => AppFailure.unexpected(error: error, stackTrace: stack),
      };
}

class _Setup {
  const _Setup({
    required this.settings,
    required this.model,
    required this.provider,
    required this.apiKey,
  });

  final AiSettings settings;
  final ModelConfig model;
  final ProviderConfig provider;
  final String apiKey;
}
