import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';

void main() {
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
