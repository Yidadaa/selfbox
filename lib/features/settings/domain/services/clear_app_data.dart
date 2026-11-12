import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../../../chat/domain/repositories/message_repository.dart';
import '../../../memory/domain/repositories/memory_repository.dart';
import '../repositories/account_repository.dart';
import '../repositories/ai_settings_repository.dart';

/// Fail fast so credentials/configuration remain retryable after a partial reset.
class ClearAppData {
  const ClearAppData(this.settings, this.messages, this.memory, this.account);
  final AiSettingsRepository settings;
  final MessageRepository messages;
  final MemoryRepository memory;
  final AccountRepository account;

  TaskEither<AppFailure, Unit> run() => settings
      .clearAll()
      .flatMap((_) => messages.clearAll())
      .flatMap((_) => memory.clearAll())
      .flatMap((_) => account.clear());
}
