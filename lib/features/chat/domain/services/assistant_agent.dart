import 'dart:math' as math;

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
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
import 'agent_history.dart';
import 'agent_model_support.dart';
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
    required this.defaultAgentName,
  });

  final AiSettingsRepository settings;
  final AccountRepository account;
  final MessageRepository messages;
  final MemoryRepository memory;
  final ImageReader readImage;
  final LanguageModelFactory models;
  final DateTime Function() clock;
  final String Function() languageTag;
  final String Function() defaultAgentName;

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
          (setup) => memory.list().flatMap(
            (index) => _run(
              setup: setup,
              question: question,
              index: index,
              userName: profile.nickname.trim(),
              agentName: profile.agentName.trim().isEmpty
                  ? defaultAgentName()
                  : profile.agentName.trim(),
              onActivity: onActivity,
              onToolEvent: onToolEvent,
              cancel: cancel,
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
    required List<MemoryEntry> index,
    required String userName,
    required String agentName,
    required void Function(AgentActivity) onActivity,
    required AgentToolTrace? onToolEvent,
    required CancellationToken? cancel,
  }) {
    final model = setup.model;
    final instructions = buildAgentInstructions(
      now: clock(),
      memory: index,
      canViewImages: model.supportsImages,
      userName: userName,
      agentName: agentName,
      languageTag: languageTag(),
    );
    final budget = math.min(
      model.shortTermMemoryTokens(setup.settings.shortTermMemoryPercent),
      model.maxInputTokens -
          model.maxOutputTokens -
          estimateTokens(instructions),
    );
    return loadAgentHistory(
      messages: messages,
      question: question,
      budget: budget,
    ).flatMap(
      (recent) => _stream(
        setup: setup,
        history: buildAgentHistory(recent),
        instructions: instructions,
        onActivity: onActivity,
        onToolEvent: onToolEvent,
        cancel: cancel,
      ),
    );
  }

  TaskEither<AppFailure, String> _stream({
    required _Setup setup,
    required List<ModelMessage> history,
    required String instructions,
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
        reasoning: agentReasoning(model),
        providerOptions: vercelGatewayProviderOptions(
          provider: setup.provider,
          model: model,
        ),
        abortSignal: cancel,
        timeout: const TimeoutConfiguration(total: timeout),
        prepareStep: (step) => attachViewedImages(step, tools),
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
  }, agentFailure);

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
