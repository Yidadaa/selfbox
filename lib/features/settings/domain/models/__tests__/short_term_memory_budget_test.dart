import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/domain/services/ai_settings_edits.dart';

void main() {
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
    for (final (value, expected) in [(-3, 10), (10, 10), (37, 37), (500, 60)]) {
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
}
