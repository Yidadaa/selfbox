import 'package:freezed_annotation/freezed_annotation.dart';

part '../../../../gen/features/settings/domain/models/app_preferences.freezed.dart';
part '../../../../gen/features/settings/domain/models/app_preferences.g.dart';

enum AppThemeChoice { system, light, dark }

enum AppLanguageChoice { zhCn, en }

enum AppRenderQuality { minimal, standard, premium }

@freezed
abstract class AppPreferences with _$AppPreferences {
  const factory AppPreferences({
    @Default(AppThemeChoice.system) AppThemeChoice theme,

    /// Null follows the device language until the user selects one.
    AppLanguageChoice? language,
    @Default(AppRenderQuality.standard) AppRenderQuality renderQuality,
    @Default(true) bool animationsEnabled,
    @Default(false) bool developerToolsUnlocked,
    @Default(false) bool onboardingCompleted,
  }) = _AppPreferences;

  factory AppPreferences.fromJson(Map<String, dynamic> json) =>
      _$AppPreferencesFromJson(json);
}
