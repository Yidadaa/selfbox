import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_app_preferences_repository.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/features/settings/presentation/pages/general_page.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void main() {
  testWidgets('cancel and failed saves keep the effective preferences', (
    tester,
  ) async {
    final repository = FakeAppPreferencesRepository();
    final container = await tester.pumpApp(preferences: repository);
    container.read(appRouterProvider).go('/me/general');
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.byKey(const ValueKey('animations-switch'))).dy,
      closeTo(tester.getCenter(find.text(t.general.animations)).dy, 0.5),
    );
    await tester.tap(find.text(t.general.rendering));
    await tester.pumpAndSettle();
    tester
        .widget<CupertinoPicker>(
          find.byKey(const ValueKey('render-quality-picker')),
        )
        .scrollController
        ?.jumpToItem(2);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.common.cancel));
    await tester.pumpAndSettle();
    expect(repository.current, const AppPreferences());
    repository.failure = const AppFailure.database(message: 'full');
    await tester.tap(find.byKey(const ValueKey('animations-switch')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<GlassSwitch>(find.byKey(const ValueKey('animations-switch')))
          .value,
      isTrue,
    );
    expect(
      MediaQuery.disableAnimationsOf(tester.element(find.byType(GeneralPage))),
      isFalse,
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  for (final brightness in Brightness.values) {
    for (final locale in AppLocale.values) {
      testWidgets('effects settings apply globally in $brightness/$locale', (
        tester,
      ) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final repository = FakeAppPreferencesRepository();
        final container = await tester.pumpApp(
          preferences: repository,
          locale: locale,
        );
        container.read(appRouterProvider).go('/me/general');
        await tester.pumpAndSettle();
        for (final (index, quality) in AppRenderQuality.values.indexed) {
          await tester.tap(find.text(t.general.rendering));
          await tester.pumpAndSettle();
          tester
              .widget<CupertinoPicker>(
                find.byKey(const ValueKey('render-quality-picker')),
              )
              .scrollController
              ?.jumpToItem(index);
          await tester.pumpAndSettle();
          await tester.tap(find.text(t.common.save));
          await tester.pumpAndSettle();
          expect(repository.current.renderQuality, quality);
          final context = tester.element(find.byType(GeneralPage));
          final expectedQuality = switch (quality) {
            AppRenderQuality.minimal => GlassQuality.minimal,
            AppRenderQuality.standard => GlassQuality.standard,
            AppRenderQuality.premium => GlassQuality.premium,
          };
          expect(
            GlassAdaptiveScopeData.of(context).effectiveQuality,
            expectedQuality,
          );
          expect(
            GlassThemeData.of(context).qualityFor(context),
            expectedQuality,
          );
          expect(
            tester
                .widgetList<GlassGroupedSection>(
                  find.byType(GlassGroupedSection),
                )
                .every((section) => section.quality == expectedQuality),
            isTrue,
          );
          expect(
            tester
                .widget<GlassIconButton>(find.byType(GlassIconButton))
                .quality,
            expectedQuality,
          );
        }
        await tester.tap(find.byKey(const ValueKey('animations-switch')));
        await tester.pumpAndSettle();
        expect(repository.current.animationsEnabled, isFalse);
        final context = tester.element(find.byType(GeneralPage));
        expect(MediaQuery.disableAnimationsOf(context), isTrue);
        expect(GlassAccessibilityData.of(context).reduceMotion, isTrue);
        await tester.tap(find.byKey(const ValueKey('animations-switch')));
        await tester.pumpAndSettle();
        expect(repository.current.animationsEnabled, isTrue);
        expect(MediaQuery.disableAnimationsOf(context), isFalse);
      });
    }
  }
}
