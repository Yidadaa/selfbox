import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/core/testing/fake_web_research_repository.dart';
import 'package:selfbox/core/testing/scripted_language_model.dart';
import 'package:selfbox/features/chat/domain/models/agent_activity.dart';

import 'assistant_agent_test_support.dart';

void main() {
  test(
    'custom prompt is present once in every model step and new turn',
    () async {
      const prompt = 'Use concise Chinese answers.\nKeep technical names.';
      final env = createAgentTestEnv([
        [
          scriptedToolCall('search_messages', {'keywords': '买'}, id: 'p1'),
        ],
        [scriptedText('好')],
        [scriptedText('再见')],
      ], settings: agentTestSettings().copyWith(customPrompt: prompt));
      expect((await askTestAgent(env)).isRight(), isTrue);
      expect((await askTestAgent(env)).isRight(), isTrue);
      expect(env.model.calls, hasLength(3));
      for (final call in env.model.calls) {
        expect(prompt.allMatches(call.prompt.system ?? ''), hasLength(1));
      }
      final settings = env.agent.settings as FakeAiSettingsRepository;
      settings.current = settings.current.copyWith(
        customPrompt: 'A revised instruction',
      );
      await askTestAgent(env);
      expect(
        env.model.calls.last.prompt.system,
        contains('A revised instruction'),
      );
      expect(env.model.calls.last.prompt.system, isNot(contains(prompt)));
    },
  );
  test('model reads a URL and receives page text in the next step', () async {
    final web = FakeWebResearchRepository();
    final env = createAgentTestEnv([
      [
        scriptedToolCall('web_read', {'url': 'https://example.com'}, id: 'w1'),
      ],
      [scriptedText('A summary of the page')],
    ], web: web);
    expect((await askTestAgent(env)).toNullable(), 'A summary of the page');
    expect(web.urls, ['https://example.com']);
    expect(env.model.calls, hasLength(2));
    final result = env.model.calls.last.prompt.messages
        .expand((message) => message.content)
        .whereType<LanguageModelV4ToolResultPart>()
        .single;
    expect(
      result.output,
      isA<ToolResultOutputText>().having(
        (output) => output.text,
        'page text',
        contains('Example page'),
      ),
    );
    expect(
      env.activity,
      contains(const AgentActivity.tool(AgentToolKind.readWeb)),
    );
  });
}
