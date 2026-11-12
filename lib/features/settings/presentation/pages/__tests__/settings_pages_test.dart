import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/presentation/pages/model_page.dart';
import 'package:selfbox/features/settings/presentation/pages/provider_page.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

const _provider = ProviderConfig(
  id: 'p1',
  name: 'My Gateway',
  format: ApiFormat.chatCompletions,
  baseUrl: 'https://gw.example.com/v1',
);

Future<ProviderContainer> _open(
  WidgetTester tester,
  String location, {
  FakeAiSettingsRepository? settings,
  FakeModelCatalog? catalog,
}) async {
  final container = await tester.pumpApp(settings: settings, catalog: catalog);
  container.read(appRouterProvider).go(location);
  await tester.pumpAndSettle();
  return container;
}

/// Lets a GlassToast finish its timer so no pending timers remain.
Future<void> _settleToasts(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
  matching: find.byType(EditableText),
);

void main() {
  group('AiProvidersPage', () {
    testWidgets('shows not-set model, history turns and an add row', (
      tester,
    ) async {
      await _open(tester, '/me/providers');

      expect(find.text(t.settings.activeModel), findsOneWidget);
      expect(find.text(t.common.notSet), findsOneWidget);
      expect(find.text('${AiSettings.defaultHistoryTurns}'), findsOneWidget);
      expect(find.text(t.settings.addProvider), findsOneWidget);
    });

    testWidgets('lists providers with enabled-model counts', (tester) async {
      await _open(
        tester,
        '/me/providers',
        settings: FakeAiSettingsRepository(
          settings: const AiSettings(
            providers: [_provider],
            models: [
              ModelConfig(providerId: 'p1', modelId: 'm', enabled: true),
            ],
          ),
        ),
      );

      expect(find.text('My Gateway'), findsOneWidget);
      expect(find.text('m'), findsOneWidget);
    });

    testWidgets('history turns can be changed from a sheet', (tester) async {
      final settings = FakeAiSettingsRepository();
      await _open(tester, '/me/providers', settings: settings);

      await tester.tap(find.text(t.settings.historyTurns));
      await tester.pumpAndSettle();
      await tester.tap(find.text('40'));
      await tester.pumpAndSettle();

      expect(settings.current.historyTurns, 40);
      expect(find.text('40'), findsOneWidget);
    });
  });

  group('ProviderPage', () {
    testWidgets('a new provider needs a name and an API key', (tester) async {
      final settings = FakeAiSettingsRepository();
      await _open(tester, '/me/provider', settings: settings);

      await tester.tap(find.text(t.common.save));
      await tester.pumpAndSettle();

      expect(find.text(t.forms.required), findsNWidgets(2));
      expect(settings.current.providers, isEmpty);
    });

    testWidgets('rejects an invalid base URL', (tester) async {
      await _open(tester, '/me/provider');

      await tester.enterText(_field(t.settings.provider.baseUrl), 'not a url');
      await tester.tap(find.text(t.common.save));
      await tester.pumpAndSettle();

      expect(find.text(t.forms.url), findsOneWidget);
    });

    testWidgets('switching format swaps an untouched default URL', (
      tester,
    ) async {
      await _open(tester, '/me/provider');

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
            .widget<EditableText>(_field(t.settings.provider.baseUrl))
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
        await _open(
          tester,
          '/me/provider',
          settings: settings,
          catalog: catalog,
        );

        await tester.enterText(_field(t.settings.provider.name), 'Gateway');
        await tester.enterText(_field(t.settings.provider.apiKey), 'sk-test');
        await tester.tap(find.text(t.common.save));
        await tester.pumpAndSettle();

        final saved = settings.current.providers.single;
        expect(saved.name, 'Gateway');
        expect(saved.format, ApiFormat.chatCompletions);
        expect(settings.keys[saved.id], 'sk-test');
        expect(catalog.calls.single.apiKey, 'sk-test');
        expect(find.text('model-a'), findsOneWidget);
        expect(find.byType(ProviderPage), findsOneWidget);
        await _settleToasts(tester);
      },
    );

    testWidgets('an existing key may be kept by leaving the field blank', (
      tester,
    ) async {
      final settings = FakeAiSettingsRepository(
        settings: const AiSettings(providers: [_provider]),
        apiKeys: {'p1': 'stored'},
      );
      await _open(tester, '/me/provider?id=p1', settings: settings);

      expect(find.text(t.settings.provider.apiKeyKept), findsOneWidget);
      await tester.enterText(_field(t.settings.provider.name), 'Renamed');
      await tester.tap(find.text(t.common.save));
      await tester.pumpAndSettle();

      expect(settings.current.providers.single.name, 'Renamed');
      expect(settings.keys['p1'], 'stored');
      await _settleToasts(tester);
    });

    testWidgets('fetch failures surface as a toast', (tester) async {
      await _open(
        tester,
        '/me/provider?id=p1',
        settings: FakeAiSettingsRepository(
          settings: const AiSettings(providers: [_provider]),
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
      await _settleToasts(tester);
    });

    testWidgets('a model switch enables it and makes it active', (
      tester,
    ) async {
      final settings = FakeAiSettingsRepository(
        settings: const AiSettings(
          providers: [_provider],
          models: [ModelConfig(providerId: 'p1', modelId: 'gpt-x')],
        ),
      );
      await _open(tester, '/me/provider?id=p1', settings: settings);

      await tester.tap(find.byType(GlassSwitch));
      await tester.pumpAndSettle();

      expect(settings.current.models.single.enabled, isTrue);
      expect(settings.current.resolvedModel?.modelId, 'gpt-x');
    });

    testWidgets('delete removes the provider and goes back', (tester) async {
      final settings = FakeAiSettingsRepository(
        settings: const AiSettings(providers: [_provider]),
        apiKeys: {'p1': 'k'},
      );
      await _open(tester, '/me/provider?id=p1', settings: settings);

      await tester.tap(find.bySemanticsLabel(t.common.more));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.settings.provider.delete));
      await tester.pumpAndSettle();

      expect(settings.current.providers, isEmpty);
      expect(settings.keys, isEmpty);
      expect(find.byType(ProviderPage), findsNothing);
    });
  });

  group('ModelPage', () {
    final base = FakeAiSettingsRepository(
      settings: const AiSettings(
        providers: [_provider],
        models: [ModelConfig(providerId: 'p1', modelId: 'gpt-x')],
      ),
    );

    testWidgets('edits capabilities and budgets', (tester) async {
      final settings = FakeAiSettingsRepository(settings: base.current);
      await _open(
        tester,
        '/me/model?provider=p1&model=gpt-x',
        settings: settings,
      );
      expect(find.byType(ModelPage), findsOneWidget);
      expect(find.text(t.settings.model.effort), findsNothing);

      // Switches in order: enabled, images, reasoning.
      await tester.tap(find.byType(GlassSwitch).at(1));
      await tester.tap(find.byType(GlassSwitch).at(2));
      await tester.pumpAndSettle();
      expect(find.text(t.settings.model.effort), findsOneWidget);
      await tester.tap(
        find
            .descendant(
              of: find.byType(GlassSegmentedControl),
              matching: find.text(t.settings.effort.high),
            )
            .first,
      );
      await tester.enterText(_field(t.settings.model.outputTokens), '16000');
      await tester.tap(find.text(t.common.save));
      await tester.pumpAndSettle();

      final model = settings.current.models.single;
      expect(model.supportsImages, isTrue);
      expect(model.supportsReasoning, isTrue);
      expect(model.reasoningEffort, ReasoningEffort.high);
      expect(model.maxOutputTokens, 16000);
      expect(find.byType(ModelPage), findsNothing);
      await _settleToasts(tester);
    });

    testWidgets('rejects non-numeric and too-small budgets', (tester) async {
      final settings = FakeAiSettingsRepository(settings: base.current);
      await _open(
        tester,
        '/me/model?provider=p1&model=gpt-x',
        settings: settings,
      );

      await tester.enterText(_field(t.settings.model.outputTokens), '12');
      await tester.enterText(_field(t.settings.model.inputTokens), 'abc');
      await tester.tap(find.text(t.common.save));
      await tester.pumpAndSettle();

      expect(find.text(t.forms.tooSmall), findsOneWidget);
      expect(find.text(t.forms.required), findsOneWidget);
      expect(
        settings.current.models.single.maxOutputTokens,
        ModelConfig.defaultOutputTokens,
      );
    });

    testWidgets('an unknown model shows the error state', (tester) async {
      await _open(tester, '/me/model?provider=p1&model=nope');
      expect(find.byIcon(Icons.memory_rounded), findsOneWidget);
    });
  });
}
