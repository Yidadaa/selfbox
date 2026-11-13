import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/icon_finder.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/theme/app_theme.dart';
import 'package:selfbox/core/widgets/app_artwork.dart';
import 'package:selfbox/core/widgets/app_list_tile.dart';
import 'package:selfbox/features/settings/presentation/pages/about_page.dart';
import 'package:selfbox/features/settings/presentation/providers/account_providers.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final locale in AppLocale.values) {
      testWidgets('about information fits 280dp in $brightness/$locale', (
        tester,
      ) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final container = await tester.pumpApp(locale: locale);
        tester.view.physicalSize = const Size(280 * 3, 640 * 3);
        container.read(appRouterProvider).go('/me/about');
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is AppArtwork && widget.artwork == BrandArt.reading,
          ),
          findsOneWidget,
        );
        expect(find.byType(GlassGroupedSection), findsOneWidget);
        expect(find.byType(AppListTile), findsNWidgets(4));
        expect(find.text('0.3.0 (3)'), findsOneWidget);
        expect(find.text('2026-11-14'), findsOneWidget);
        expect(find.text(t.me.tagline), findsNothing);
        expect(find.text(t.app.name), findsNothing);
        expect(findAppIcon(AppIcons.appVersion), findsOneWidget);
        expect(findAppIcon(AppIcons.updateDate), findsOneWidget);
        expect(findAppIcon(AppIcons.agreement), findsOneWidget);
        expect(findAppIcon(AppIcons.website), findsOneWidget);

        final agreement = tester.widget<AppListTile>(
          find.widgetWithText(AppListTile, t.me.userAgreement),
        );
        final website = tester.widget<AppListTile>(
          find.widgetWithText(AppListTile, t.me.officialWebsite),
        );
        expect(agreement.onTap, isNull);
        expect(website.onTap, isNull);
        expect(agreement.value, isNull);
        expect(website.value, isNull);
        expect(findAppIcon(AppIcons.next), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('version loading and retry keep the information rows', (
    tester,
  ) async {
    tester.usePhoneViewport();
    LocaleSettings.setLocaleSync(AppLocale.en);
    final pending = Completer<String>();
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appVersionProvider.overrideWith((ref) async {
            return ++attempts == 1 ? pending.future : '0.3.0 (3)';
          }),
        ],
        child: TranslationProvider(
          child: LiquidGlassWidgets.wrap(
            brightnessResolver: Theme.maybeBrightnessOf,
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const AboutPage(),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(AppListTile), findsNWidgets(4));
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Skeletonizer && widget.enabled,
      ),
      findsOneWidget,
    );
    final rowHeight = tester.getSize(find.byType(AppListTile).first).height;
    pending.completeError(StateError('package info unavailable'));
    await tester.pumpAndSettle();
    expect(find.text(t.common.retry), findsOneWidget);
    expect(find.byType(AppListTile), findsNWidgets(4));
    expect(tester.getSize(find.byType(AppListTile).first).height, rowHeight);
    await tester.tap(find.text(t.common.retry));
    await tester.pumpAndSettle();
    expect(find.text('0.3.0 (3)'), findsOneWidget);
    expect(tester.getSize(find.byType(AppListTile).first).height, rowHeight);
    expect(tester.takeException(), isNull);
  });
}
