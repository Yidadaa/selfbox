import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../gen/i18n/strings.g.dart';
import '../../data/settings_data_providers.dart';
import '../../domain/models/app_preferences.dart';

part '../../../../gen/features/settings/presentation/providers/app_preferences_controller.g.dart';

@Riverpod(keepAlive: true)
AppPreferences initialAppPreferences(Ref ref) => const AppPreferences();

@Riverpod(keepAlive: true)
class AppPreferencesController extends _$AppPreferencesController {
  @override
  AppPreferences build() => ref.watch(initialAppPreferencesProvider);

  Future<Either<AppFailure, Unit>> setTheme(AppThemeChoice theme) =>
      _save(state.copyWith(theme: theme));

  Future<Either<AppFailure, Unit>> setLanguage(AppLanguageChoice language) =>
      _save(state.copyWith(language: language));

  Future<Either<AppFailure, Unit>> _save(AppPreferences next) async {
    if (next == state) return const Right(unit);
    final previousLanguage = state.language;
    final result = await ref
        .read(appPreferencesRepositoryProvider)
        .save(next)
        .run();
    if (result.isRight()) {
      state = next;
      if (next.language != previousLanguage) _applyLanguage(next.language);
    }
    return result;
  }

  Future<Either<AppFailure, Unit>> clear() async {
    final result = await ref
        .read(appPreferencesRepositoryProvider)
        .clearAll()
        .run();
    if (result.isRight()) {
      final languageChanged = state.language != null;
      state = const AppPreferences();
      if (languageChanged) _applyLanguage(null);
    }
    return result;
  }
}

void applyPreferredLanguage(AppLanguageChoice? language) =>
    _applyLanguage(language);

void _applyLanguage(AppLanguageChoice? language) {
  switch (language) {
    case null:
      LocaleSettings.useDeviceLocaleSync();
    case AppLanguageChoice.zhCn:
      LocaleSettings.setLocaleSync(AppLocale.zhCn);
    case AppLanguageChoice.en:
      LocaleSettings.setLocaleSync(AppLocale.en);
  }
}
