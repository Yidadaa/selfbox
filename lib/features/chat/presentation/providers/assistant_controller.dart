import 'dart:async';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/logger/talker_provider.dart';
import '../../../../core/time/clock.dart';
import '../../../memory/data/memory_data_providers.dart';
import '../../../settings/data/settings_data_providers.dart';
import '../../data/chat_data_providers.dart';
import '../../domain/models/agent_activity.dart';
import '../../domain/models/message.dart';
import '../../domain/services/assistant_agent.dart';

part '../../../../gen/features/chat/presentation/providers/assistant_controller.freezed.dart';
part '../../../../gen/features/chat/presentation/providers/assistant_controller.g.dart';

@freezed
sealed class AssistantState with _$AssistantState {
  const factory AssistantState.idle() = AssistantIdle;

  const factory AssistantState.working(AgentActivity activity) =
      AssistantWorking;

  const factory AssistantState.failed(AppFailure failure, Message question) =
      AssistantFailed;
}

@Riverpod(keepAlive: true)
AssistantAgent assistantAgent(Ref ref) => AssistantAgent(
  settings: ref.watch(aiSettingsRepositoryProvider),
  messages: ref.watch(messageRepositoryProvider),
  memory: ref.watch(memoryRepositoryProvider),
  readImage: ref.watch(mediaStoreProvider).read,
  models: ref.watch(languageModelFactoryProvider),
  clock: ref.watch(clockProvider),
);

/// AI mode: one question at a time. A newer question cancels the running
/// one, and the reply is stored as an AI message once complete.
@Riverpod(keepAlive: true)
class AssistantController extends _$AssistantController {
  CancellationToken? _cancel;
  var _run = 0;

  @override
  AssistantState build() {
    ref.onDispose(() => _cancel?.cancel());
    return const AssistantState.idle();
  }

  Future<void> ask(Message question) async {
    _cancel?.cancel();
    final token = _cancel = CancellationToken();
    final run = ++_run;
    bool current() => run == _run;

    state = const AssistantState.working(AgentActivity.thinking());
    final answer = await ref
        .read(assistantAgentProvider)
        .answer(
          question,
          cancel: token,
          onActivity: (activity) {
            if (current()) state = AssistantState.working(activity);
          },
        )
        .run();
    // A superseded run must not post its (now stale) reply.
    if (!current()) return;
    final result = await TaskEither.fromEither(answer)
        .flatMap(
          (text) => ref
              .read(messageRepositoryProvider)
              .add(MessageDraft(author: MessageAuthor.ai, text: text))
              .map((_) => unit),
        )
        .run();
    if (!current()) return;
    state = result.match((failure) {
      ref.read(talkerProvider).error('Assistant failed', failure);
      return AssistantState.failed(failure, question);
    }, (_) => const AssistantState.idle());
  }

  Future<void> retry() => switch (state) {
    AssistantFailed(:final question) => ask(question),
    AssistantIdle() || AssistantWorking() => Future.value(),
  };

  void dismiss() {
    if (state is AssistantFailed) state = const AssistantState.idle();
  }
}
