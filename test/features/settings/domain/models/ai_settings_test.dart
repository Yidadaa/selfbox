import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/domain/services/ai_settings_edits.dart';

const _openai = ProviderConfig(
  id: 'p1',
  name: 'OpenAI',
  format: ApiFormat.responses,
  baseUrl: 'https://api.openai.com/v1',
);

ModelConfig _model(String provider, String id, {bool enabled = false}) =>
    ModelConfig(providerId: provider, modelId: id, enabled: enabled);

void main() {
  group('AiSettings', () {
    test('round-trips through JSON', () {
      final settings = AiSettings(
        providers: [
          _openai.copyWith(headers: const {'X-Client': 'selfbox'}),
        ],
        models: [
          _model('p1', 'a', enabled: true).copyWith(
            supportsReasoning: true,
            reasoningEffort: ReasoningEffort.high,
          ),
        ],
        activeModel: const ModelRef(providerId: 'p1', modelId: 'a'),
        shortTermMemoryPercent: 35,
      );
      expect(AiSettings.fromJson(settings.toJson()), settings);
    });

    test('provider headers default to an empty map', () {
      expect(
        ProviderConfig.fromJson(const {
          'id': 'p',
          'name': 'Gateway',
          'format': 'chatCompletions',
          'baseUrl': 'https://example.com/v1',
        }).headers,
        isEmpty,
      );
    });

    test('defaults are usable on an empty document', () {
      final settings = AiSettings.fromJson(const {});
      expect(
        settings.shortTermMemoryPercent,
        AiSettings.defaultShortTermMemoryPercent,
      );
      expect(settings.resolvedModel, isNull);
    });

    test('resolvedModel ignores a stale active reference', () {
      final settings = AiSettings(
        models: [_model('p1', 'a', enabled: true)],
        activeModel: const ModelRef(providerId: 'p1', modelId: 'gone'),
      );
      expect(settings.resolvedModel?.modelId, 'a');
    });

    test('api formats default to their vendor endpoints', () {
      expect(ApiFormat.messages.defaultBaseUrl, contains('anthropic'));
      expect(ApiFormat.chatCompletions.defaultBaseUrl, contains('openai'));
    });
  });

  group('AiSettingsSchema', () {
    test('base URL must be http(s)', () {
      expect(
        AiSettingsSchema.baseUrl.validate('https://example.com/v1').isValid,
        isTrue,
      );
      expect(AiSettingsSchema.baseUrl.validate('ftp://x.com').isValid, isFalse);
      expect(AiSettingsSchema.baseUrl.validate('not a url').isValid, isFalse);
      expect(AiSettingsSchema.baseUrl.validate(null).isValid, isFalse);
    });

    test('token budgets reject zero, negatives and absurd values', () {
      expect(AiSettingsSchema.outputTokens.validate(4096).isValid, isTrue);
      expect(AiSettingsSchema.outputTokens.validate(0).isValid, isFalse);
      expect(AiSettingsSchema.inputTokens.validate(-1).isValid, isFalse);
      expect(
        AiSettingsSchema.inputTokens
            .validate(AiSettingsSchema.maxTokens + 1)
            .isValid,
        isFalse,
      );
    });

    test('provider names must be non-empty and short', () {
      expect(AiSettingsSchema.providerName.validate('').isValid, isFalse);
      expect(
        AiSettingsSchema.providerName
            .validate('x' * (AiSettingsSchema.maxNameLength + 1))
            .isValid,
        isFalse,
      );
    });
  });
  test('defaults to 20 percent and ignores the legacy message count', () {
    expect(const AiSettings().shortTermMemoryPercent, 20);
    for (final turns in [0, 5, 100]) {
      final settings = AiSettings.fromJson({'historyTurns': turns});
      expect(settings.shortTermMemoryPercent, 20);
      expect(settings.toJson(), isNot(contains('historyTurns')));
    }
  });

  test('persists the new percentage and bounds stored outliers', () {
    for (final (stored, expected) in [(3, 10), (20, 20), (60, 60), (99, 60)]) {
      final settings = AiSettings.fromJson({
        'shortTermMemoryPercent': stored,
        'historyTurns': 80,
      });
      expect(settings.shortTermMemoryPercent, expected);
      expect(AiSettings.fromJson(settings.toJson()), settings);
    }
  });

  test('percentage edits clamp to 10 through 60', () {
    for (final (value, expected) in [
      (-3, 10),
      (10, 10),
      (12, 12),
      (37, 37),
      (500, 60),
    ]) {
      expect(
        const AiSettings()
            .withShortTermMemoryPercent(value)
            .shortTermMemoryPercent,
        expected,
      );
    }
  });

  test('uses full model context as denominator, independently of output', () {
    const model = ModelConfig(providerId: 'p', modelId: 'm');
    expect(model.shortTermMemoryTokens(20), 25600);
    expect(model.shortTermMemoryTokens(10), 12800);
    expect(model.shortTermMemoryTokens(60), 76800);
    expect(
      model.copyWith(maxOutputTokens: 20000).shortTermMemoryTokens(20),
      25600,
    );
    expect(
      model.copyWith(maxInputTokens: 64000).shortTermMemoryTokens(20),
      12800,
    );
    expect(
      model.copyWith(maxInputTokens: 10001).shortTermMemoryTokens(20),
      2000,
    );
  });

  test('schema accepts only integral percentages within range', () {
    for (final value in [10, 20, 60]) {
      expect(
        AiSettingsSchema.shortTermMemoryPercent.validate(value).isValid,
        isTrue,
      );
    }
    for (final value in [null, 9, 61, 20.5, '20']) {
      expect(
        AiSettingsSchema.shortTermMemoryPercent.validate(value).isValid,
        isFalse,
      );
    }
  });
  test(
    'old settings default to empty and multiline instructions round trip',
    () {
      expect(AiSettings.fromJson({}).customPrompt, '');
      const settings = AiSettings(customPrompt: '请用中文\n回答简短一点。');
      expect(AiSettings.fromJson(settings.toJson()), settings);
      expect(settings.copyWith(customPrompt: '').customPrompt, '');
    },
  );
  test(
    'prompt schema allows empty and rejects excess length and invalid types',
    () {
      for (final value in [
        '',
        '多行\n提示词',
        'x' * AiSettingsSchema.maxCustomPromptLength,
      ]) {
        expect(AiSettingsSchema.customPrompt.validate(value).isValid, isTrue);
      }
      for (final value in [
        null,
        42,
        'x' * (AiSettingsSchema.maxCustomPromptLength + 1),
      ]) {
        expect(AiSettingsSchema.customPrompt.validate(value).isValid, isFalse);
      }
    },
  );
}
