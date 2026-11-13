import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/scripted_language_model.dart';
import 'package:selfbox/features/chat/domain/models/agent_activity.dart';
import 'package:selfbox/features/chat/domain/services/assistant_agent.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/domain/models/user_profile.dart';

import 'assistant_agent_test_support.dart';

void main() {
  group('AssistantAgent', () {
    test(
      'uses separate Agent and user names in the actual model request',
      () async {
        for (final name in ['', 'Momo']) {
          final env = createAgentTestEnv([
            [scriptedText('hello')],
          ], profile: UserProfile(nickname: 'Flynn', agentName: name));
          await askTestAgent(env);
          final text = env.model.calls.single.prompt.system;
          expect(text, contains('Your name is ${name.isEmpty ? '小懒' : name}.'));
          expect(text, contains("User's current name: Flynn."));
        }
      },
    );
    test(
      'streams cumulative reasoning Markdown but no answer preview',
      () async {
        final env = createAgentTestEnv([
          [
            scriptedReasoning('先检查记录\n正在整'),
            scriptedReasoning('理'),
            scriptedText('第一段\n最终答'),
            scriptedText('案'),
          ],
        ]);

        expect((await askTestAgent(env)).toNullable(), '第一段\n最终答案');
        expect(env.activity, [
          const AgentActivity.thinking(),
          const AgentActivity.thinking(text: '先检查记录\n正在整'),
          const AgentActivity.thinking(text: '先检查记录\n正在整理'),
          const AgentActivity.typing(),
        ]);
      },
    );

    test('a tool resets reasoning before the next step', () async {
      final env = createAgentTestEnv([
        [
          scriptedReasoning('旧思考'),
          scriptedToolCall('search_messages', {'keywords': '买'}, id: 's1'),
        ],
        [scriptedReasoning('新思考'), scriptedText('好')],
      ]);

      expect((await askTestAgent(env)).toNullable(), '好');
      expect(env.activity, [
        const AgentActivity.thinking(),
        const AgentActivity.thinking(text: '旧思考'),
        const AgentActivity.tool(AgentToolKind.searchMessages),
        const AgentActivity.thinking(segment: 1),
        const AgentActivity.thinking(text: '新思考', segment: 1),
        const AgentActivity.typing(),
      ]);
    });

    test(
      'whitespace-only opening deltas do not replace the fallback',
      () async {
        final env = createAgentTestEnv([
          [
            scriptedReasoning(' '),
            scriptedReasoning('\n'),
            scriptedReasoning('# 进度\n**新**'),
            scriptedText('完成'),
          ],
        ]);

        await askTestAgent(env);
        expect(env.activity, [
          const AgentActivity.thinking(),
          const AgentActivity.thinking(text: ' \n# 进度\n**新**'),
          const AgentActivity.typing(),
        ]);
      },
    );

    test(
      'long reasoning keeps a bounded tail without splitting an emoji',
      () async {
        final longLine =
            '${List.filled(4096, 'a').join()}😀'
            '${List.filled(4091, 'b').join()}😀结尾';
        final env = createAgentTestEnv([
          [scriptedReasoning(longLine), scriptedText('好')],
        ]);

        await askTestAgent(env);
        final preview = (env.activity[1] as AgentThinking).text;
        expect(preview.length, lessThanOrEqualTo(8192));
        expect(preview, endsWith('😀结尾'));
        expect(preview.runes.first, isNot(0xFFFD));
        expect(preview.runes.first, 'b'.runes.single);
        expect((env.activity[1] as AgentThinking).segment, 1);
      },
    );

    test('answers directly when no tools are needed', () async {
      final env = createAgentTestEnv([
        [scriptedText('你说过要买牛奶和面包。')],
      ]);

      expect((await askTestAgent(env)).toNullable(), '你说过要买牛奶和面包。');
      expect(env.activity, [
        const AgentActivity.thinking(),
        const AgentActivity.typing(),
      ]);
      expect(env.factory.created.single.apiKey, 'sk');
      expect(env.factory.created.single.modelId, 'm1');
      expect(env.factory.disposed, 1);
    });

    test('sends instructions, history and budgets to the model', () async {
      final env = createAgentTestEnv([
        [scriptedText('ok')],
      ]);
      await askTestAgent(env);

      final call = env.model.calls.single;
      expect(call.maxOutputTokens, 1000);
      expect(call.prompt.system, contains('Selfbox'));
      final userText = call.prompt.messages
          .where((m) => m.role == LanguageModelV4Role.user)
          .expand((m) => m.content)
          .whereType<LanguageModelV4TextPart>()
          .map((p) => p.text)
          .join();
      expect(userText, contains('[#1 2026-11-05 08:00] 买牛奶和面包'));
      expect(userText, contains('我上周说要买什么？'));
      expect(call.tools.map((t) => t.name), contains('search_messages'));
      expect(call.tools.map((t) => t.name), isNot(contains('view_image')));
    });

    test(
      'passes Vercel Gateway reasoning options to the SDK request',
      () async {
        final env = createAgentTestEnv(
          [
            [scriptedText('ok')],
          ],
          settings: AiSettings(
            providers: [
              agentTestProvider.copyWith(
                format: ApiFormat.responses,
                baseUrl: 'https://ai-gateway.vercel.sh/v1',
              ),
            ],
            models: [
              const ModelConfig(
                providerId: 'p1',
                modelId: 'openai/gpt-5',
                enabled: true,
                supportsReasoning: true,
                reasoningEffort: ReasoningEffort.high,
              ),
            ],
          ),
        );

        await askTestAgent(env);

        expect(env.model.calls.single.providerOptions, {
          'openai': {
            'reasoning': {'effort': 'high', 'summary': 'auto'},
          },
        });
      },
    );

    test(
      'runs a multi-step tool loop and reports only the latest tool',
      () async {
        final env = createAgentTestEnv([
          [
            scriptedToolCall('search_messages', {'keywords': '买'}, id: 's1'),
          ],
          [
            scriptedToolCall('memory_create', {
              'path': 'topic/shopping.md',
              'content': '# 购物\n- 牛奶、面包',
            }, id: 'c1'),
          ],
          [scriptedText('上周你记了：买牛奶和面包。')],
        ]);

        final answer = await askTestAgent(env);

        expect(answer.toNullable(), '上周你记了：买牛奶和面包。');
        expect(env.model.calls, hasLength(3));
        expect(env.activity, [
          const AgentActivity.thinking(),
          const AgentActivity.tool(AgentToolKind.searchMessages),
          const AgentActivity.thinking(segment: 1),
          const AgentActivity.tool(AgentToolKind.writeMemory),
          const AgentActivity.thinking(segment: 2),
          const AgentActivity.typing(),
        ]);
        expect(env.memory.contentOf('topic/shopping.md'), contains('牛奶'));

        // The second request carries the first tool's result.
        final toolResults = env.model.calls[1].prompt.messages
            .expand((m) => m.content)
            .whereType<LanguageModelV4ToolResultPart>();
        expect(toolResults.single.toolName, 'search_messages');
      },
    );

    test('attaches a viewed image right after the view_image result', () async {
      final env = createAgentTestEnv([
        [
          scriptedToolCall('view_image', {'message_id': 2}, id: 'v1'),
        ],
        [scriptedText('是一张极光照片。')],
      ], settings: agentTestSettings(images: true));

      expect((await askTestAgent(env)).toNullable(), '是一张极光照片。');
      final messages = env.model.calls[1].prompt.messages;
      final resultIndex = messages.indexWhere(
        (m) => m.content.whereType<LanguageModelV4ToolResultPart>().isNotEmpty,
      );
      final next = messages[resultIndex + 1];
      expect(next.role, LanguageModelV4Role.user);
      final image = next.content.single as LanguageModelV4ImagePart;
      expect(image.mediaType, 'image/png');
      expect((image.image as DataContentBytes).bytes, [1, 2, 3]);
    });

    test('fails fast without an enabled model', () async {
      final env = createAgentTestEnv([], settings: const AiSettings());
      final failure = (await askTestAgent(env)).getLeft().toNullable();

      expect(
        failure,
        const AppFailure.validation(message: AssistantAgent.noModel),
      );
      expect(env.factory.created, isEmpty);
      expect(env.activity, isEmpty);
    });

    test('fails fast without an API key', () async {
      final env = createAgentTestEnv([], keys: const {});
      expect(
        (await askTestAgent(env)).getLeft().toNullable(),
        const AppFailure.validation(message: AppFailure.missingApiKey),
      );
    });

    test('maps provider HTTP errors to network failures', () async {
      final env = createAgentTestEnv(
        [],
        error: const AiApiCallError('bad key', statusCode: 401),
      );
      final failure = (await askTestAgent(env)).getLeft().toNullable();

      expect(failure, isA<NetworkFailure>());
      expect((failure! as NetworkFailure).statusCode, 401);
      expect(env.factory.disposed, 1);
    });

    test('an empty final answer is a failure, not a blank bubble', () async {
      final env = createAgentTestEnv([
        [scriptedText('   ')],
      ]);
      expect(
        (await askTestAgent(env)).getLeft().toNullable(),
        isA<NetworkFailure>(),
      );
    });
  });
}
