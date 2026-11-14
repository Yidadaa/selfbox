import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/core/testing/icon_finder.dart';
import 'package:selfbox/core/theme/app_dialog_tokens.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/widgets/app_list_tile.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'settings_test_support.dart';

void main() {
  group('AiProvidersPage', () {
    testWidgets('shows not-set model, memory percentage and an add row', (
      tester,
    ) async {
      await openSettingsPage(tester, '/me/providers');

      expect(find.text(t.settings.activeModel), findsOneWidget);
      expect(find.text(t.common.notSet), findsOneWidget);
      expect(
        find.text('${AiSettings.defaultShortTermMemoryPercent}%'),
        findsOneWidget,
      );
      expect(find.text(t.settings.addProvider), findsOneWidget);
    });

    for (final locale in AppLocale.values) {
      testWidgets('provider count and model icons in ${locale.name}', (
        tester,
      ) async {
        final settings = FakeAiSettingsRepository(
          settings: const AiSettings(
            providers: [testProvider, otherTestProvider],
            models: [
              ModelConfig(providerId: 'p2', modelId: 'a', enabled: true),
              ModelConfig(providerId: 'p2', modelId: 'b', enabled: true),
              ModelConfig(providerId: 'p2', modelId: 'c', enabled: true),
              ModelConfig(providerId: 'p2', modelId: 'd', enabled: true),
              ModelConfig(providerId: 'p2', modelId: 'e', enabled: true),
              ModelConfig(providerId: 'p2', modelId: 'f'),
            ],
          ),
        );
        final container = await tester.pumpApp(
          settings: settings,
          locale: locale,
        );
        container.read(appRouterProvider).go('/me/providers');
        await tester.pumpAndSettle();

        final modelTile = find.widgetWithText(
          AppListTile,
          t.settings.activeModel,
        );
        expect(
          find.descendant(
            of: modelTile,
            matching: findAppIcon(AppIcons.modelSelection),
          ),
          findsOneWidget,
        );
        final providerTile = find.widgetWithText(AppListTile, 'Other Gateway');
        expect(
          find.descendant(
            of: providerTile,
            matching: findAppIcon(AppIcons.provider),
          ),
          findsOneWidget,
        );
        expect(
          tester.widget<AppListTile>(providerTile).subtitle,
          locale == AppLocale.en ? 'Responses (5 models)' : 'Responses (5 个模型)',
        );
        expect(
          tester
              .widget<AppListTile>(
                find.widgetWithText(AppListTile, 'My Gateway'),
              )
              .subtitle,
          '${t.settings.format.chatCompletions} (${locale == AppLocale.en ? '0 models' : '0 个模型'})',
        );
        await settings
            .save(
              settings.current.copyWith(
                models: const [
                  ModelConfig(providerId: 'p2', modelId: 'a', enabled: true),
                ],
              ),
            )
            .run();
        await tester.pumpAndSettle();
        expect(
          tester.widget<AppListTile>(providerTile).subtitle,
          locale == AppLocale.en ? 'Responses (1 model)' : 'Responses (1 个模型)',
        );
      });
    }

    testWidgets('model picker starts on the current model and saves a change', (
      tester,
    ) async {
      final settings = FakeAiSettingsRepository(
        settings: const AiSettings(
          providers: [testProvider, otherTestProvider],
          models: [
            ModelConfig(providerId: 'p1', modelId: 'model-a', enabled: true),
            ModelConfig(providerId: 'p1', modelId: 'model-b', enabled: true),
            ModelConfig(providerId: 'p2', modelId: 'model-a', enabled: true),
          ],
          activeModel: ModelRef(providerId: 'p1', modelId: 'model-b'),
        ),
      );
      await openSettingsPage(tester, '/me/providers', settings: settings);

      await tester.tap(find.text(t.settings.activeModel));
      await tester.pumpAndSettle();

      final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
      expect(sheet.backgroundColor, Colors.white);
      expect(sheet.shape, AppDialogTokens.sheetShape);
      final picker = tester.widget<CupertinoPicker>(
        find.byKey(const ValueKey('model-picker')),
      );
      expect(picker.scrollController!.selectedItem, 1);
      expect(find.text('Other Gateway · model-a'), findsOneWidget);

      picker.scrollController!.jumpToItem(2);
      await tester.pumpAndSettle();
      expect(
        settings.current.activeModel,
        const ModelRef(providerId: 'p1', modelId: 'model-b'),
      );
      await tester.tap(find.text(t.common.save));
      await tester.pumpAndSettle();

      expect(
        settings.current.activeModel,
        const ModelRef(providerId: 'p2', modelId: 'model-a'),
      );
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('cancelling model picker preserves the current model', (
      tester,
    ) async {
      final settings = FakeAiSettingsRepository(
        settings: const AiSettings(
          providers: [testProvider],
          models: [
            ModelConfig(providerId: 'p1', modelId: 'model-a', enabled: true),
            ModelConfig(providerId: 'p1', modelId: 'model-b', enabled: true),
          ],
          activeModel: ModelRef(providerId: 'p1', modelId: 'model-a'),
        ),
      );
      await openSettingsPage(tester, '/me/providers', settings: settings);

      await tester.tap(find.text(t.settings.activeModel));
      await tester.pumpAndSettle();
      tester
          .widget<CupertinoPicker>(find.byKey(const ValueKey('model-picker')))
          .scrollController!
          .jumpToItem(1);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.cancel));
      await tester.pumpAndSettle();

      expect(
        settings.current.activeModel,
        const ModelRef(providerId: 'p1', modelId: 'model-a'),
      );
    });

    testWidgets('model picker stays unavailable without enabled models', (
      tester,
    ) async {
      await openSettingsPage(tester, '/me/providers');

      await tester.tap(find.text(t.settings.activeModel));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('model and memory sheets use dark opaque surfaces', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await openSettingsPage(
        tester,
        '/me/providers',
        settings: FakeAiSettingsRepository(
          settings: const AiSettings(
            providers: [testProvider],
            models: [
              ModelConfig(providerId: 'p1', modelId: 'model-a', enabled: true),
            ],
          ),
        ),
      );

      for (final (label, key, cancel) in [
        (
          t.settings.activeModel,
          const ValueKey('model-picker'),
          find.text(t.common.cancel),
        ),
        (
          t.settings.shortTermMemory,
          const ValueKey('short-term-memory-slider'),
          find.text(t.common.cancel),
        ),
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
        expect(sheet.backgroundColor, AppGlassTheme.dark.bubbleOther);
        expect(sheet.backgroundColor!.computeLuminance(), lessThan(0.15));
        expect(find.byKey(key), findsOneWidget);
        final title = tester.widget<Text>(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text(label),
          ),
        );
        expect(title.style?.color, AppGlassTheme.dark.onBubbleOther);
        await tester.tap(cancel);
        await tester.pumpAndSettle();
      }
    });
  });
}
