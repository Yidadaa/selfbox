import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';

void main() {
  test('old preferences keep standard rendering and enabled animations', () {
    final preferences = AppPreferences.fromJson({'theme': 'dark'});
    expect(preferences.renderQuality, AppRenderQuality.standard);
    expect(preferences.animationsEnabled, isTrue);
    expect(preferences.developerToolsUnlocked, isFalse);
    final unlocked = preferences.copyWith(developerToolsUnlocked: true);
    expect(AppPreferences.fromJson(unlocked.toJson()), unlocked);
    for (final quality in AppRenderQuality.values) {
      final selected = preferences.copyWith(
        renderQuality: quality,
        animationsEnabled: false,
      );
      expect(AppPreferences.fromJson(selected.toJson()), selected);
    }
  });

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
