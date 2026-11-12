import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/router/app_dock_tabs.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_app_preferences_repository.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/features/settings/presentation/pages/general_page.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void main() {
  testWidgets('Me opens General above the tab bar with current values', (
    tester,
  ) async {
    final container = await tester.pumpApp();
    container.read(appRouterProvider).go('/me');
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.me.general));
    await tester.pumpAndSettle();
    expect(find.byType(GeneralPage), findsOneWidget);
    expect(find.byType(AppDockTabs), findsNothing);
    expect(find.text(t.general.theme), findsOneWidget);
    expect(find.text(t.general.language), findsOneWidget);
    expect(find.text(t.general.system), findsOneWidget);
    expect(find.text(t.general.english), findsOneWidget);
  });

  testWidgets('theme picker saves a choice and updates MaterialApp', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final repository = FakeAppPreferencesRepository();
    final container = await tester.pumpApp(preferences: repository);
    container.read(appRouterProvider).go('/me/general');
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.general.theme));
    await tester.pumpAndSettle();
    final picker = tester.widget<CupertinoPicker>(
      find.byKey(const ValueKey('theme-picker')),
    );
    expect(picker.scrollController?.selectedItem, 0);
    picker.scrollController?.jumpToItem(1);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();

    expect(repository.current.theme, AppThemeChoice.light);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    expect(find.text(t.general.light), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      Theme.of(tester.element(find.byType(GeneralPage))).brightness,
      Brightness.light,
    );

    await tester.tap(find.text(t.general.theme));
    await tester.pumpAndSettle();
    tester
        .widget<CupertinoPicker>(find.byKey(const ValueKey('theme-picker')))
        .scrollController
        ?.jumpToItem(0);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(repository.current.theme, AppThemeChoice.system);
    expect(
      Theme.of(tester.element(find.byType(GeneralPage))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('saved choices initialize the page and both pickers', (
    tester,
  ) async {
    final repository = FakeAppPreferencesRepository(
      current: const AppPreferences(
        theme: AppThemeChoice.dark,
        language: AppLanguageChoice.zhCn,
      ),
    );
    final container = await tester.pumpApp(
      preferences: repository,
      initialPreferences: repository.current,
      locale: AppLocale.zhCn,
    );
    container.read(appRouterProvider).go('/me/general');
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.tap(find.text(t.general.theme));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CupertinoPicker>(find.byKey(const ValueKey('theme-picker')))
          .scrollController
          ?.selectedItem,
      2,
    );
    await tester.tap(find.text(t.common.cancel));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.general.language));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CupertinoPicker>(
            find.byKey(const ValueKey('language-picker')),
          )
          .scrollController
          ?.selectedItem,
      0,
    );
  });

  testWidgets('language picker changes the whole app immediately', (
    tester,
  ) async {
    final repository = FakeAppPreferencesRepository();
    final container = await tester.pumpApp(preferences: repository);
    container.read(appRouterProvider).go('/me/general');
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.general.language));
    await tester.pumpAndSettle();
    final picker = tester.widget<CupertinoPicker>(
      find.byKey(const ValueKey('language-picker')),
    );
    expect(picker.scrollController?.selectedItem, 1);
    picker.scrollController?.jumpToItem(0);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();

    expect(repository.current.language, AppLanguageChoice.zhCn);
    expect(LocaleSettings.currentLocale, AppLocale.zhCn);
    expect(find.text('通用'), findsOneWidget);
    expect(find.text('主题'), findsOneWidget);
    expect(find.text('语言'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);

    await tester.tap(find.text(t.general.language));
    await tester.pumpAndSettle();
    tester
        .widget<CupertinoPicker>(find.byKey(const ValueKey('language-picker')))
        .scrollController
        ?.jumpToItem(1);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(repository.current.language, AppLanguageChoice.en);
    expect(LocaleSettings.currentLocale, AppLocale.en);
    expect(find.text('General'), findsOneWidget);
  });

  testWidgets('cancelling a picker does not save a change', (tester) async {
    final repository = FakeAppPreferencesRepository();
    final container = await tester.pumpApp(preferences: repository);
    container.read(appRouterProvider).go('/me/general');
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.general.theme));
    await tester.pumpAndSettle();
    tester
        .widget<CupertinoPicker>(find.byKey(const ValueKey('theme-picker')))
        .scrollController
        ?.jumpToItem(2);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.common.cancel));
    await tester.pumpAndSettle();
    expect(repository.current, const AppPreferences());
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
  });

  testWidgets('a failed save keeps the picker open and theme unchanged', (
    tester,
  ) async {
    final repository = FakeAppPreferencesRepository()
      ..failure = const AppFailure.database(message: 'disk full');
    final container = await tester.pumpApp(preferences: repository);
    container.read(appRouterProvider).go('/me/general');
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.general.theme));
    await tester.pumpAndSettle();
    tester
        .widget<CupertinoPicker>(find.byKey(const ValueKey('theme-picker')))
        .scrollController
        ?.jumpToItem(1);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.common.save));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(repository.current, const AppPreferences());
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('picker sheet follows the dark surface tokens', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final container = await tester.pumpApp();
    container.read(appRouterProvider).go('/me/general');
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.general.theme));
    await tester.pumpAndSettle();
    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.backgroundColor, AppGlassTheme.dark.bubbleOther);
    expect(find.byKey(const ValueKey('theme-picker')), findsOneWidget);
    expect(
      tester
          .widget<GlassGroupedSection>(find.byType(GlassGroupedSection))
          .quality,
      GlassQuality.standard,
    );
  });
}
