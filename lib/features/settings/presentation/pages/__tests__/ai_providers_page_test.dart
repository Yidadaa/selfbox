import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
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

    testWidgets('lists providers with enabled-model counts', (tester) async {
      await openSettingsPage(
        tester,
        '/me/providers',
        settings: FakeAiSettingsRepository(
          settings: const AiSettings(
            providers: [testProvider],
            models: [
              ModelConfig(providerId: 'p1', modelId: 'm', enabled: true),
            ],
          ),
        ),
      );

      expect(find.text('My Gateway'), findsOneWidget);
      expect(find.text('m'), findsOneWidget);
    });

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
      expect(
        sheet.shape,
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
      );
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
