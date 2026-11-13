import 'dart:typed_data';

import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/fake_memory_repository.dart';
import 'package:selfbox/core/testing/fake_message_repository.dart';
import 'package:selfbox/core/testing/fake_web_research_repository.dart';
import 'package:selfbox/core/testing/scripted_language_model.dart';
import 'package:selfbox/features/chat/domain/models/agent_activity.dart';
import 'package:selfbox/features/chat/domain/repositories/web_research_repository.dart';
import 'package:selfbox/features/chat/domain/services/agent_tools.dart';

import 'assistant_agent_test_support.dart';

AgentTools _tools(FakeWebResearchRepository web) => AgentTools(
  messages: FakeMessageRepository(),
  memory: FakeMemoryRepository(),
  web: web,
  readImage: (_) => TaskEither.right(Uint8List(0)),
  canViewImages: false,
);

Future<Map<String, Object?>> _call(
  AgentTools tools,
  String name,
  Map<String, Object?> input,
) async =>
    (await tools.build()[name]!.executeDynamic!(
          input,
          const ToolExecutionOptions(toolCallId: 'web'),
        ))!
        as Map<String, Object?>;

void main() {
  test(
    'web_read hard-cuts pages and caches stable continuation offsets',
    () async {
      final web = FakeWebResearchRepository()
        ..page = WebPageContent(
          title: 'Article',
          url: 'https://example.com/article',
          text: '中' * 15000,
        );
      final tools = _tools(web);
      final first = await _call(tools, 'web_read', {'url': web.page.url});
      expect((first['text']! as String).length, 6000);
      expect(first['next_offset'], 6000);
      expect(first['untrusted'], isTrue);
      final second = await _call(tools, 'web_read', {
        'url': web.page.url,
        'offset': first['next_offset'],
        'max_chars': 999999,
      });
      expect((second['text']! as String).length, 9000);
      expect(second['next_offset'], isNull);
      expect(web.urls, hasLength(1));
      expect(
        await _call(tools, 'web_read', {'url': web.page.url, 'offset': -1}),
        contains('error'),
      );
      expect(
        await _call(tools, 'web_read', {'url': web.page.url, 'offset': 99999}),
        contains('error'),
      );
    },
  );

  test('hard cut never splits a supplementary Unicode character', () async {
    final web = FakeWebResearchRepository()
      ..page = WebPageContent(
        title: 'Emoji boundary',
        url: 'https://example.com/unicode',
        text: '${'x' * 999}😀${'y' * 1000}',
      );
    final tools = _tools(web);
    final first = await _call(tools, 'web_read', {
      'url': web.page.url,
      'max_chars': 1000,
    });
    expect(first['text'], 'x' * 999);
    expect(first['next_offset'], 999);
    final second = await _call(tools, 'web_read', {
      'url': web.page.url,
      'offset': first['next_offset'],
      'max_chars': 1000,
    });
    expect((second['text']! as String).startsWith('😀'), isTrue);
  });

  test(
    'web errors return actionable tool results without ending the turn',
    () async {
      final web = FakeWebResearchRepository()
        ..failure = const AppFailure.network(message: 'timeout');
      final tools = _tools(web);
      expect(await _call(tools, 'web_search', {'query': 'dart'}), {
        'error': 'timeout',
      });
      expect(await _call(tools, 'web_read', {'url': 'https://example.com'}), {
        'error': 'timeout',
      });
    },
  );

  test(
    'assistant loop searches, reads and answers with web activities',
    () async {
      final web = FakeWebResearchRepository()
        ..hits = const [
          WebSearchHit(
            title: 'Example',
            url: 'https://example.com',
            snippet: 'A result',
          ),
        ];
      final env = createAgentTestEnv([
        [
          scriptedToolCall('web_search', {'query': 'example'}, id: 'search'),
        ],
        [
          scriptedToolCall('web_read', {
            'url': 'https://example.com',
          }, id: 'read'),
        ],
        [scriptedText('Answer from https://example.com')],
      ], web: web);
      expect(
        (await askTestAgent(env)).toNullable(),
        'Answer from https://example.com',
      );
      expect(web.queries, ['example']);
      expect(web.urls, ['https://example.com']);
      expect(
        env.activity,
        contains(const AgentActivity.tool(AgentToolKind.searchWeb)),
      );
      expect(
        env.activity,
        contains(const AgentActivity.tool(AgentToolKind.readWeb)),
      );
      expect(env.model.calls.first.prompt.system, contains('untrusted data'));
      expect(env.model.calls.first.prompt.system, contains('next_offset'));
    },
  );
}
