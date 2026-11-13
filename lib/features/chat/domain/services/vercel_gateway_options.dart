import 'package:ai_sdk_provider/ai_sdk_provider.dart';

import '../../../settings/domain/models/ai_settings.dart';

/// Returns whether [baseUrl] points at Vercel's AI Gateway endpoint.
///
/// The host check is intentionally exact so a lookalike host cannot enable
/// Gateway-specific request options accidentally.
bool isVercelAiGateway(String baseUrl) {
  final uri = Uri.tryParse(baseUrl.trim());
  if (uri == null || uri.host.toLowerCase() != 'ai-gateway.vercel.sh') {
    return false;
  }
  return uri.scheme.toLowerCase() == 'https' ||
      uri.scheme.toLowerCase() == 'http';
}

/// Builds the provider options required for reasoning summaries through the
/// Vercel AI Gateway's OpenAI-compatible adapter.
///
/// The SDK's generic [LanguageModelV4Reasoning] setting controls the model's
/// reasoning budget. These provider options additionally ask the upstream
/// provider to return a textual reasoning summary that the stream parser can
/// expose as `StreamTextReasoningDeltaEvent` values.
ProviderOptions? vercelGatewayProviderOptions({
  required ProviderConfig provider,
  required ModelConfig model,
}) {
  if (!isVercelAiGateway(provider.baseUrl) ||
      !model.supportsReasoning ||
      provider.format == ApiFormat.messages) {
    return null;
  }

  final modelKind = _modelKind(model.modelId);
  return switch (modelKind) {
    _GatewayModelKind.gpt => _gptOptions(
      provider.format,
      model.reasoningEffort,
    ),
    _GatewayModelKind.gemini => _geminiOptions(model.reasoningEffort),
    _GatewayModelKind.claudeAdaptive => _claudeAdaptiveOptions(),
    _GatewayModelKind.claude => _claudeOptions(),
    _GatewayModelKind.deepSeek => _deepSeekOptions(model.reasoningEffort),
    _GatewayModelKind.unknown => null,
  };
}

enum _GatewayModelKind {
  gpt,
  gemini,
  claude,
  claudeAdaptive,
  deepSeek,
  unknown,
}

_GatewayModelKind _modelKind(String modelId) {
  final normalized = modelId.trim().toLowerCase();
  if (_hasModelPrefix(normalized, 'openai') || normalized.startsWith('gpt-')) {
    return _GatewayModelKind.gpt;
  }
  if (_hasModelPrefix(normalized, 'google') ||
      _hasModelPrefix(normalized, 'vertex') ||
      normalized.startsWith('gemini-')) {
    return _GatewayModelKind.gemini;
  }
  if (_hasModelPrefix(normalized, 'anthropic') ||
      normalized.startsWith('claude-')) {
    final isAdaptive =
        normalized.contains('adaptive') ||
        RegExp(r'claude-(?:opus|sonnet|haiku)-4\.6').hasMatch(normalized);
    return isAdaptive
        ? _GatewayModelKind.claudeAdaptive
        : _GatewayModelKind.claude;
  }
  if (_hasModelPrefix(normalized, 'deepseek') ||
      normalized.startsWith('deepseek-')) {
    return _GatewayModelKind.deepSeek;
  }
  return _GatewayModelKind.unknown;
}

bool _hasModelPrefix(String modelId, String prefix) =>
    modelId == prefix || modelId.startsWith('$prefix/');

ProviderOptions _gptOptions(ApiFormat format, ReasoningEffort effort) =>
    format == ApiFormat.responses
    ? {
        'openai': {
          'reasoning': {'effort': _effortName(effort), 'summary': 'auto'},
        },
      }
    : {
        'openai': {'reasoning_summary': 'auto'},
      };

ProviderOptions _geminiOptions(ReasoningEffort effort) {
  final thinkingConfig = {
    'thinkingBudget': _thinkingBudget(effort),
    'includeThoughts': true,
  };
  return {
    'openai': {
      'providerOptions': {
        'google': {'thinkingConfig': thinkingConfig},
        'vertex': {'thinkingConfig': thinkingConfig},
      },
    },
  };
}

ProviderOptions _claudeOptions() => {
  'openai': {
    'reasoning': {'enabled': true, 'max_tokens': 5000, 'exclude': false},
  },
};

ProviderOptions _claudeAdaptiveOptions() => {
  'openai': {
    'reasoning': {'effort': 'high'},
    'providerOptions': {
      'anthropic': {
        'thinking': {'type': 'adaptive', 'display': 'summarized'},
      },
    },
  },
};

ProviderOptions _deepSeekOptions(ReasoningEffort effort) => {
  'openai': {
    'reasoning': {
      'enabled': true,
      'effort': _effortName(effort),
      'exclude': false,
    },
  },
};

String _effortName(ReasoningEffort effort) => switch (effort) {
  ReasoningEffort.minimal => 'minimal',
  ReasoningEffort.low => 'low',
  ReasoningEffort.medium => 'medium',
  ReasoningEffort.high => 'high',
  ReasoningEffort.xhigh => 'xhigh',
};

int _thinkingBudget(ReasoningEffort effort) => switch (effort) {
  ReasoningEffort.minimal => 1024,
  ReasoningEffort.low => 2048,
  ReasoningEffort.medium => 4096,
  ReasoningEffort.high => 8192,
  ReasoningEffort.xhigh => 16384,
};
