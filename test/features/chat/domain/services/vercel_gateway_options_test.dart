import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/chat/domain/services/vercel_gateway_options.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';

ProviderConfig _provider({
  String baseUrl = 'https://ai-gateway.vercel.sh/v1',
  ApiFormat format = ApiFormat.responses,
}) => ProviderConfig(
  id: 'gateway',
  name: 'Vercel Gateway',
  format: format,
  baseUrl: baseUrl,
);

ModelConfig _model(
  String modelId, {
  bool supportsReasoning = true,
  ReasoningEffort effort = ReasoningEffort.high,
}) => ModelConfig(
  providerId: 'gateway',
  modelId: modelId,
  supportsReasoning: supportsReasoning,
  reasoningEffort: effort,
);

void main() {
  group('isVercelAiGateway', () {
    test('accepts the gateway host with normalized URL variations', () {
      expect(isVercelAiGateway('https://ai-gateway.vercel.sh/v1'), isTrue);
      expect(
        isVercelAiGateway('HTTPS://AI-GATEWAY.VERCEL.SH/v1/?tenant=test'),
        isTrue,
      );
    });

    test('rejects another host and malformed values', () {
      expect(isVercelAiGateway('https://api.openai.com/v1'), isFalse);
      expect(
        isVercelAiGateway('https://ai-gateway.vercel.sh.evil/v1'),
        isFalse,
      );
      expect(isVercelAiGateway('not a url'), isFalse);
    });
  });

  group('vercelGatewayProviderOptions', () {
    test(
      'does not configure non-gateway, non-reasoning, or messages providers',
      () {
        expect(
          vercelGatewayProviderOptions(
            provider: _provider(baseUrl: 'https://api.openai.com/v1'),
            model: _model('openai/gpt-5'),
          ),
          isNull,
        );
        expect(
          vercelGatewayProviderOptions(
            provider: _provider(),
            model: _model('openai/gpt-5', supportsReasoning: false),
          ),
          isNull,
        );
        expect(
          vercelGatewayProviderOptions(
            provider: _provider(format: ApiFormat.messages),
            model: _model('anthropic/claude-sonnet-4.5'),
          ),
          isNull,
        );
      },
    );

    test('requests a reasoning summary for GPT Responses', () {
      expect(
        vercelGatewayProviderOptions(
          provider: _provider(),
          model: _model('openai/gpt-5'),
        ),
        {
          'openai': {
            'reasoning': {'effort': 'high', 'summary': 'auto'},
          },
        },
      );
    });

    test('requests a reasoning summary for GPT Chat Completions', () {
      expect(
        vercelGatewayProviderOptions(
          provider: _provider(format: ApiFormat.chatCompletions),
          model: _model('gpt-5', effort: ReasoningEffort.medium),
        ),
        {
          'openai': {'reasoning_summary': 'auto'},
        },
      );
    });

    test('enables Gemini thoughts through both Gateway route aliases', () {
      final options = vercelGatewayProviderOptions(
        provider: _provider(),
        model: _model('google/gemini-2.5-flash'),
      );

      expect(options, isNotNull);
      expect(options!['openai']!['providerOptions'], {
        'google': {
          'thinkingConfig': {'thinkingBudget': 8192, 'includeThoughts': true},
        },
        'vertex': {
          'thinkingConfig': {'thinkingBudget': 8192, 'includeThoughts': true},
        },
      });
    });

    test('uses fixed-budget reasoning for Claude models', () {
      expect(
        vercelGatewayProviderOptions(
          provider: _provider(),
          model: _model('anthropic/claude-sonnet-4.5'),
        ),
        {
          'openai': {
            'reasoning': {
              'enabled': true,
              'max_tokens': 5000,
              'exclude': false,
            },
          },
        },
      );
    });

    test('uses adaptive summarized reasoning when the model advertises it', () {
      expect(
        vercelGatewayProviderOptions(
          provider: _provider(),
          model: _model('anthropic/claude-opus-4.6'),
        ),
        {
          'openai': {
            'reasoning': {'effort': 'high'},
            'providerOptions': {
              'anthropic': {
                'thinking': {'type': 'adaptive', 'display': 'summarized'},
              },
            },
          },
        },
      );
    });

    test('enables reasoning for DeepSeek', () {
      expect(
        vercelGatewayProviderOptions(
          provider: _provider(),
          model: _model('deepseek/deepseek-r1', effort: ReasoningEffort.low),
        ),
        {
          'openai': {
            'reasoning': {'enabled': true, 'effort': 'low', 'exclude': false},
          },
        },
      );
    });
  });
}
