import 'dart:async';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../../../chat/domain/repositories/language_model_factory.dart';
import '../../domain/models/ai_settings.dart';
import '../../domain/repositories/model_probe.dart';

class SdkModelProbe implements ModelProbe {
  const SdkModelProbe(
    this._factory, {
    this.timeout = const Duration(seconds: 20),
  });

  final LanguageModelFactory _factory;
  final Duration timeout;

  @override
  TaskEither<AppFailure, Unit> test(
    ProviderConfig provider,
    String apiKey,
    ModelConfig model,
  ) => TaskEither.tryCatch(() async {
    final handle = _factory.create(provider, apiKey, model.modelId);
    try {
      await generateText<Object?>(
        model: handle.model,
        prompt: 'Reply with OK.',
        maxOutputTokens: 64,
        maxRetries: 0,
        timeout: TimeoutConfiguration(total: timeout),
      );
      return unit;
    } finally {
      handle.dispose();
    }
  }, _failure);

  static AppFailure _failure(Object error, StackTrace stack) => switch (error) {
    final AppFailure failure => failure,
    AiRetryError(:final lastError) => _failure(lastError, stack),
    AiApiCallError(:final message, :final statusCode) => AppFailure.network(
      message: message,
      statusCode: statusCode,
    ),
    TimeoutException() || AiOperationCancelledError() =>
      const AppFailure.network(message: 'timed out'),
    _ => AppFailure.unexpected(error: error, stackTrace: stack),
  };
}
