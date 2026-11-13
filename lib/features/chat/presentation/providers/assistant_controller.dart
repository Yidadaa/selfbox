import 'dart:async';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/logger/talker_provider.dart';
import '../../../../core/time/clock.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../../memory/data/memory_data_providers.dart';
import '../../../settings/data/settings_data_providers.dart';
import '../../../settings/presentation/providers/account_providers.dart';
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
  account: ref.watch(accountRepositoryProvider),
  messages: ref.watch(messageRepositoryProvider),
  memory: ref.watch(memoryRepositoryProvider),
  readImage: ref.watch(mediaStoreProvider).read,
  models: ref.watch(languageModelFactoryProvider),
  clock: ref.watch(clockProvider),
  languageTag: () => LocaleSettings.currentLocale.languageTag,
  defaultAgentName: () => t.me.agentDefaultName,
);

/// Publishes the id of a newly persisted AI reply once per completed turn.
/// The timeline consumes this edge-triggered value so old replies never replay.
@Riverpod(keepAlive: true)
class AssistantReplyEvent extends _$AssistantReplyEvent {
  @override
  int? build() => null;

  void publish(int messageId) => state = messageId;
}

/// AI mode: one question at a time. A newer question cancels the running
/// one, and the reply is stored as an AI message once complete.
@Riverpod(keepAlive: true)
class AssistantController extends _$AssistantController {
  CancellationToken? _cancel;
  var _run = 0;
  final _pending = <Future<void>>{};

  Future<void> cancelAndWait() async {
    ++_run;
    _cancel?.cancel();
    await Future.wait(_pending.toList());
    state = const AssistantState.idle();
  }

  @override
  AssistantState build() {
    ref.onDispose(() => _cancel?.cancel());
    return const AssistantState.idle();
  }

  Future<void> ask(Message question) {
    final task = _ask(question);
    _pending.add(task);
    return task.whenComplete(() => _pending.remove(task));
  }

  Future<void> _ask(Message question) async {
    _cancel?.cancel();
    final token = _cancel = CancellationToken();
    final run = ++_run;
    bool current() => run == _run;
    final talker = ref.read(talkerProvider);

    talker.info('Agent #$run started message=${question.id}');
    state = const AssistantState.working(AgentActivity.thinking());
    final answer = await ref
        .read(assistantAgentProvider)
        .answer(
          question,
          cancel: token,
          onActivity: (activity) {
            if (current()) state = AssistantState.working(activity);
          },
          onToolEvent: (name, phase) =>
              talker.info('Agent #$run tool $name ${phase.name}'),
        )
        .run();
    // A superseded run must not post its (now stale) reply.
    if (!current()) {
      talker.info('Agent #$run cancelled');
      return;
    }
    final result = await TaskEither.fromEither(answer)
        .flatMap(
          (text) => ref
              .read(messageRepositoryProvider)
              .add(MessageDraft(author: MessageAuthor.ai, text: text)),
        )
        .run();
    if (!current()) return;
    state = result.match(
      (failure) {
        talker.error('Agent #$run failed', failure);
        return AssistantState.failed(failure, question);
      },
      (message) {
        ref.read(assistantReplyEventProvider.notifier).publish(message.id);
        talker.info('Agent #$run completed');
        return const AssistantState.idle();
      },
    );
  }

  Future<void> retry() => switch (state) {
    AssistantFailed(:final question) => ask(question),
    AssistantIdle() || AssistantWorking() => Future.value(),
  };

  void dismiss() {
    if (state is AssistantFailed) state = const AssistantState.idle();
  }
}
