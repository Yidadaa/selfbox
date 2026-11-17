import 'dart:async';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/features/chat/domain/services/assistant_agent.dart';

import '../../../../support/scripted_language_model.dart';
import 'assistant_agent_test_support.dart';

const _temporary = AiApiCallError(
  'temporarily unavailable',
  statusCode: 503,
  isRetryable: true,
  responseHeaders: {'Retry-After': '0'},
);

class _RetryModel extends ScriptedLanguageModel {
  _RetryModel(
    super.steps, {
    this.failures = const {},
    this.brokenStream = false,
  });

  final Map<int, Object> failures;
  final bool brokenStream;
  final attempts = <LanguageModelV4CallOptions>[];
  final firstFailure = Completer<void>();

  @override
  Future<LanguageModelV4StreamResult> doStream(
    LanguageModelV4CallOptions options,
  ) async {
    attempts.add(options);
    if (failures[attempts.length] case final failure?) {
      if (!firstFailure.isCompleted) firstFailure.complete();
      return Future.error(failure);
    }
    final response = await super.doStream(options);
    if (!brokenStream || calls.length != 2) return response;
    return LanguageModelV4StreamResult(
      stream: Stream<LanguageModelV4StreamPart>.error(_temporary),
    );
  }
}

void main() {
  test('single API call succeeds on its fourth attempt', () async {
    final env = createAgentTestEnv([]);
    final model = _RetryModel(
      [
        [scriptedText('recovered')],
      ],
      failures: {1: _temporary, 2: _temporary, 3: _temporary},
    );
    env.factory.model = model;

    expect((await askTestAgent(env)).toNullable(), 'recovered');
    expect(model.attempts, hasLength(4));
    expect(
      model.attempts.every((call) => identical(call, model.attempts.first)),
      isTrue,
    );
    expect(env.factory.disposed, 1);
  });

  test(
    'retry budget stops after four attempts and preserves final failure',
    () async {
      final env = createAgentTestEnv([]);
      final model = _RetryModel(
        [],
        failures: {
          for (var attempt = 1; attempt <= 5; attempt++) attempt: _temporary,
        },
      );
      env.factory.model = model;

      expect(
        (await askTestAgent(env)).getLeft().toNullable(),
        const AppFailure.network(
          message: 'temporarily unavailable',
          statusCode: 503,
        ),
      );
      expect(model.attempts, hasLength(4));
      expect(env.factory.disposed, 1);
    },
  );

  test(
    'each loop step gets its own budget without executing a tool twice',
    () async {
      final env = createAgentTestEnv([]);
      final model = _RetryModel(
        [
          [
            scriptedToolCall('memory_create', {
              'path': 'topic/retry.md',
              'content': 'once',
            }, id: 'write1'),
          ],
          [scriptedText('done')],
        ],
        failures: {
          for (final attempt in [1, 2, 3, 5, 6, 7]) attempt: _temporary,
        },
      );
      env.factory.model = model;
      final phases = <AgentToolPhase>[];

      final result = await env.agent
          .answer(
            agentTestQuestion,
            onActivity: env.activity.add,
            onToolEvent: (_, phase) => phases.add(phase),
          )
          .run();

      expect(result.toNullable(), 'done');
      expect(model.attempts, hasLength(8));
      expect(phases, [AgentToolPhase.started, AgentToolPhase.succeeded]);
      expect(env.memory.contentOf('topic/retry.md'), 'once\n');
      expect(
        model.attempts.last.prompt.messages
            .expand((message) => message.content)
            .whereType<LanguageModelV4ToolResultPart>()
            .single
            .toolCallId,
        'write1',
      );
      expect(env.factory.disposed, 1);
    },
  );

  for (final status in [400, 401, 403]) {
    test('permanent HTTP $status failure is not retried', () async {
      final env = createAgentTestEnv([]);
      final model = _RetryModel(
        [],
        failures: {
          1: AiApiCallError.fromResponse(
            statusCode: status,
            body: 'invalid request',
          ),
        },
      );
      env.factory.model = model;
      expect((await askTestAgent(env)).isLeft(), isTrue);
      expect(model.attempts, hasLength(1));
      expect(env.factory.disposed, 1);
    });
  }

  test(
    'cancellation during Retry-After stops further attempts promptly',
    () async {
      final env = createAgentTestEnv([]);
      final model = _RetryModel(
        [],
        failures: {
          1: AiApiCallError.fromResponse(
            statusCode: 429,
            responseHeaders: {'Retry-After': '60'},
            body: 'rate limited',
          ),
        },
      );
      env.factory.model = model;
      final cancel = CancellationToken();
      final pending = env.agent
          .answer(
            agentTestQuestion,
            onActivity: env.activity.add,
            cancel: cancel,
          )
          .run();
      await model.firstFailure.future;
      await Future<void>.delayed(Duration.zero);
      cancel.cancel();
      expect(
        (await pending.timeout(const Duration(seconds: 1))).isLeft(),
        isTrue,
      );
      expect(model.attempts, hasLength(1));
      expect(env.factory.disposed, 1);
    },
  );

  test('broken acquired stream does not replay completed tools', () async {
    final env = createAgentTestEnv([]);
    final model = _RetryModel([
      [
        scriptedToolCall('memory_create', {
          'path': 'topic/stream.md',
          'content': 'once',
        }, id: 'write1'),
      ],
      [scriptedText('discarded')],
    ], brokenStream: true);
    env.factory.model = model;
    final phases = <AgentToolPhase>[];
    final result = await env.agent
        .answer(
          agentTestQuestion,
          onActivity: env.activity.add,
          onToolEvent: (_, phase) => phases.add(phase),
        )
        .run();
    expect(result.isLeft(), isTrue);
    expect(model.attempts, hasLength(2));
    expect(phases, [AgentToolPhase.started, AgentToolPhase.succeeded]);
    expect(env.memory.contentOf('topic/stream.md'), 'once\n');
    expect(env.factory.disposed, 1);
  });
}
