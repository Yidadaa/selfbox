import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/core/widgets/app_confirm_dialog.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/presentation/pages/provider_page.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'settings_test_support.dart';

void main() {
  group('ProviderPage', () {
    testWidgets(
      'provider controls use standard glass quality for a lower render cost',
      (tester) async {
        await openSettingsPage(
          tester,
          '/me/provider?id=p1',
          settings: FakeAiSettingsRepository(
            settings: const AiSettings(
              providers: [testProvider],
              models: [
                ModelConfig(
                  providerId: 'p1',
                  modelId: 'reasoning-model',
                  enabled: true,
                  supportsReasoning: true,
                ),
              ],
            ),
          ),
        );

        final controls = tester
            .widgetList<GlassSegmentedControl>(
              find.byType(GlassSegmentedControl),
            )
            .toList(growable: false);
        expect(controls, hasLength(2));
        expect(
          controls.every((control) => control.quality == GlassQuality.standard),
          isTrue,
        );
        final switches = tester
            .widgetList<GlassSwitch>(find.byType(GlassSwitch))
            .toList(growable: false);
        expect(switches, hasLength(2));
        expect(
          switches.every((control) => control.quality == GlassQuality.standard),
          isTrue,
        );
        final iconButtons = tester
            .widgetList<GlassIconButton>(find.byType(GlassIconButton))
            .toList(growable: false);
        expect(iconButtons, hasLength(2));
        expect(
          iconButtons.every(
            (button) => button.quality == GlassQuality.standard,
          ),
          isTrue,
        );
      },
    );

    testWidgets('no models shows only unframed small text', (tester) async {
      await openSettingsPage(
        tester,
        '/me/provider?id=p1',
        settings: FakeAiSettingsRepository(
          settings: const AiSettings(providers: [testProvider]),
        ),
      );

      final empty = find.text(t.settings.provider.noAddedModels);
      expect(empty, findsOneWidget);
      expect(
        find.ancestor(of: empty, matching: find.byType(GlassGroupedSection)),
        findsNothing,
      );
      expect(find.byIcon(Icons.inventory_2_outlined), findsNothing);
    });

    testWidgets('a new provider needs a name and an API key', (tester) async {
      final settings = FakeAiSettingsRepository();
      await openSettingsPage(tester, '/me/provider', settings: settings);

      await tester.tap(find.text(t.common.save));
      await tester.pumpAndSettle();

      expect(find.text(t.forms.required), findsNWidgets(2));
      expect(settings.current.providers, isEmpty);
    });

    testWidgets('rejects an invalid base URL', (tester) async {
      await openSettingsPage(tester, '/me/provider');

      await tester.enterText(
        settingsField(t.settings.provider.baseUrl),
        'not a url',
      );
      await tester.tap(find.text(t.common.save));
      await tester.pumpAndSettle();

      expect(find.text(t.forms.url), findsOneWidget);
    });

    testWidgets('switching format swaps an untouched default URL', (
      tester,
    ) async {
      await openSettingsPage(tester, '/me/provider');

      await tester.tap(
        find
            .descendant(
              of: find.byType(GlassSegmentedControl),
              matching: find.text(t.settings.format.messages),
            )
            .first,
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<EditableText>(settingsField(t.settings.provider.baseUrl))
            .controller
            .text,
        ApiFormat.messages.defaultBaseUrl,
      );
    });

    testWidgets(
      'saving a new provider stores it, its key, and fetches models',
      (tester) async {
        final settings = FakeAiSettingsRepository();
        final catalog = FakeModelCatalog();
        await openSettingsPage(
          tester,
          '/me/provider',
          settings: settings,
          catalog: catalog,
        );

        await tester.enterText(
          settingsField(t.settings.provider.name),
          'Gateway',
        );
        await tester.enterText(
          settingsField(t.settings.provider.apiKey),
          'sk-test',
        );
        await tester.tap(find.text(t.common.save));
        await tester.pumpAndSettle();

        final saved = settings.current.providers.single;
        expect(saved.name, 'Gateway');
        expect(saved.format, ApiFormat.chatCompletions);
        expect(settings.keys[saved.id], 'sk-test');
        expect(catalog.calls.single.apiKey, 'sk-test');
        expect(settings.current.models, hasLength(2));
        expect(find.text('model-a'), findsNothing);
        expect(find.byType(ProviderPage), findsOneWidget);
        await settleSettingsToasts(tester);
      },
    );

    testWidgets('an existing key may be kept by leaving the field blank', (
      tester,
    ) async {
      final settings = FakeAiSettingsRepository(
        settings: const AiSettings(providers: [testProvider]),
        apiKeys: {'p1': 'stored'},
      );
      await openSettingsPage(tester, '/me/provider?id=p1', settings: settings);

      expect(find.text(t.settings.provider.apiKeyKept), findsOneWidget);
      await tester.enterText(
        settingsField(t.settings.provider.name),
        'Renamed',
      );
      await tester.tap(find.text(t.common.save));
      await tester.pumpAndSettle();

      expect(settings.current.providers.single.name, 'Renamed');
      expect(settings.keys['p1'], 'stored');
      await settleSettingsToasts(tester);
    });

    testWidgets('fetch failures surface as a toast', (tester) async {
      await openSettingsPage(
        tester,
        '/me/provider?id=p1',
        settings: FakeAiSettingsRepository(
          settings: const AiSettings(providers: [testProvider]),
          apiKeys: {'p1': 'bad'},
        ),
        catalog: FakeModelCatalog(
          const Left(AppFailure.network(message: 'no', statusCode: 401)),
        ),
      );

      await tester.tap(find.text(t.settings.provider.fetchModels));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(t.settings.errors.auth), findsOneWidget);
      await settleSettingsToasts(tester);
    });

    testWidgets('delete removes the provider and goes back', (tester) async {
      final settings = FakeAiSettingsRepository(
        settings: const AiSettings(providers: [testProvider]),
        apiKeys: {'p1': 'k'},
      );
      await openSettingsPage(tester, '/me/provider?id=p1', settings: settings);

      await tester.tap(find.bySemanticsLabel(t.common.more));
      await tester.pumpAndSettle();
      expect(find.byType(AppConfirmDialog), findsOneWidget);
      await tester.tap(find.text(t.common.cancel));
      await tester.pumpAndSettle();
      expect(settings.current.providers, hasLength(1));

      await tester.tap(find.bySemanticsLabel(t.common.more));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.settings.provider.delete));
      await tester.pumpAndSettle();

      expect(settings.current.providers, isEmpty);
      expect(settings.keys, isEmpty);
      expect(find.byType(ProviderPage), findsNothing);
    });
  });
}
