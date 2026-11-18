import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/theme/sdk_cupertino.dart';
import 'package:selfbox/core/widgets/app_list_tile.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/features/settings/domain/repositories/app_preferences_repository.dart';
import 'package:selfbox/features/settings/presentation/providers/app_preferences_controller.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void registerTests(
  Future<ProviderContainer> Function(
    WidgetTester,
    AppPreferencesRepository,
    AppPreferences,
  )
  pumpApp,
) {
  testWidgets('automatic language restores device locale and persists null', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('zh', 'CN')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final repository = _PreferencesRepository(
      current: const AppPreferences(language: AppLanguageChoice.en),
    );
    final container = await pumpApp(tester, repository, repository.current);
    container.read(appRouterProvider).go('/me/general');
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.general.language));
    await tester.pumpAndSettle();
    final picker = tester.widget<CupertinoPicker>(
      find.byKey(const ValueKey('language-picker')),
    );
    picker.scrollController?.jumpToItem(0);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(repository.current.language, isNull);
    expect(LocaleSettings.currentLocale, AppLocale.zhCn);
    expect(
      tester
          .widget<AppListTile>(
            find.widgetWithText(AppListTile, t.general.language),
          )
          .value,
      '自动',
    );
    tester.platformDispatcher.localesTestValue = [const Locale('en')];
    await tester.pumpAndSettle();
    expect(LocaleSettings.currentLocale, AppLocale.en);
    expect(repository.current.language, isNull);
  });

  testWidgets(
    'failed automatic language and developer toggle retain saved state',
    (tester) async {
      final repository = _PreferencesRepository(
        current: const AppPreferences(
          language: AppLanguageChoice.en,
          developerToolsUnlocked: true,
        ),
      );
      final container = await pumpApp(tester, repository, repository.current);
      final controller = container.read(
        appPreferencesControllerProvider.notifier,
      );
      repository.failure = const AppFailure.database(message: 'full');
      expect((await controller.setLanguage(null)).isLeft(), isTrue);
      expect((await controller.toggleDeveloperTools()).isLeft(), isTrue);
      expect(
        container.read(appPreferencesControllerProvider).language,
        AppLanguageChoice.en,
      );
      expect(
        container.read(appPreferencesControllerProvider).developerToolsUnlocked,
        isTrue,
      );
      expect(LocaleSettings.currentLocale, AppLocale.en);
      repository.failure = null;
      expect((await controller.toggleDeveloperTools()).isRight(), isTrue);
      expect(repository.current.developerToolsUnlocked, isFalse);
      expect((await controller.toggleDeveloperTools()).isRight(), isTrue);
      expect(repository.current.developerToolsUnlocked, isTrue);
    },
  );
}

class _PreferencesRepository implements AppPreferencesRepository {
  _PreferencesRepository({required this.current});
  AppPreferences current;
  AppFailure? failure;

  @override
  TaskEither<AppFailure, AppPreferences> load() => TaskEither.right(current);

  @override
  TaskEither<AppFailure, Unit> save(AppPreferences preferences) =>
      TaskEither.fromEither(
        Option.fromNullable(failure).match(() {
          current = preferences;
          return const Right(unit);
        }, Left.new),
      );

  @override
  TaskEither<AppFailure, Unit> clearAll() => save(const AppPreferences());
}
