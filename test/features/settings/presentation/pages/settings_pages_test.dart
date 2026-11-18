import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/core/widgets/app_list_tile.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/domain/models/app_preferences.dart';
import 'package:selfbox/features/settings/presentation/providers/app_preferences_controller.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../../../support/fake_ai_settings.dart';
import '../../../../support/icon_finder.dart';
import 'settings_test_support.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'settings sections and forms share liquid surfaces in $brightness',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final container = await openSettingsPage(
          tester,
          '/me',
          settings: FakeAiSettingsRepository(
            settings: const AiSettings(
              providers: [testProvider],
              models: [
                ModelConfig(providerId: 'p1', modelId: 'gpt-x', enabled: true),
              ],
            ),
          ),
        );
        final router = container.read(appRouterProvider);
        expectLiquidSections(tester, 1);
        expect(
          find.descendant(
            of: find.widgetWithText(AppListTile, t.me.providers),
            matching: findAppIcon(AppIcons.aiConfig),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.widgetWithText(AppListTile, t.me.about),
            matching: findAppIcon(AppIcons.about),
          ),
          findsOneWidget,
        );

        for (final (location, count, field) in [
          ('/me/general', 2, null),
          ('/me/providers', 2, null),
          ('/me/storage', 1, null),
          ('/me/provider?id=p1', 2, t.settings.provider.name),
          (
            '/me/model?provider=p1&model=gpt-x',
            1,
            t.settings.model.inputTokens,
          ),
        ]) {
          router.go(location);
          await tester.pumpAndSettle();
          final solid = location.startsWith('/me/provider?');
          expectLiquidSections(tester, count, solid: solid);
          if (field != null) expectLiquidFormCard(tester, field, solid: solid);
          if (solid) {
            await container
                .read(appPreferencesControllerProvider.notifier)
                .setRenderQuality(AppRenderQuality.minimal);
            await tester.pumpAndSettle();
            final surfaces = tester
                .widgetList<GlassContainer>(find.byType(GlassContainer))
                .where(
                  (card) =>
                      card.shape is LiquidRoundedSuperellipse &&
                      (card.shape as LiquidRoundedSuperellipse).borderRadius ==
                          28,
                );
            expect(surfaces, hasLength(3));
            for (final surface in surfaces) {
              expect(surface.shape.side.width, 0.75);
              expect(surface.shape.side.color.a, inExclusiveRange(0, 0.15));
            }
            await container
                .read(appPreferencesControllerProvider.notifier)
                .setRenderQuality(AppRenderQuality.standard);
            await tester.pumpAndSettle();
          }
        }
      },
    );
  }
}
