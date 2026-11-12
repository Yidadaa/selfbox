import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';

void main() {
  test('preferences default to system theme and device language', () {
    const preferences = AppPreferences();
    expect(preferences.theme, AppThemeChoice.system);
    expect(preferences.language, isNull);
  });

  test('theme and language round-trip through JSON and copyWith', () {
    const preferences = AppPreferences(
      theme: AppThemeChoice.dark,
      language: AppLanguageChoice.zhCn,
    );
    expect(AppPreferences.fromJson(preferences.toJson()), preferences);
    expect(
      preferences.copyWith(theme: AppThemeChoice.light),
      const AppPreferences(
        theme: AppThemeChoice.light,
        language: AppLanguageChoice.zhCn,
      ),
    );
  });
}
