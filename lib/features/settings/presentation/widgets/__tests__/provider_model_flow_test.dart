import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/widgets/app_confirm_dialog.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

const _provider = ProviderConfig(
  id: 'p1',
  name: 'Gateway',
  format: ApiFormat.chatCompletions,
  baseUrl: 'https://gw.example.com/v1',
);

Future<void> _open(
  WidgetTester tester,
  String location, {
  required FakeAiSettingsRepository settings,
  FakeModelCatalog? catalog,
}) async {
  final container = await tester.pumpApp(settings: settings, catalog: catalog);
  container.read(appRouterProvider).go(location);
  await tester.pumpAndSettle();
}

Finder _formField(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

Finder _providerField(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
  matching: find.byType(EditableText),
);

void main() {
  testWidgets('format picker keeps a custom endpoint when format changes', (
    tester,
  ) async {
    await _open(tester, '/me/provider', settings: FakeAiSettingsRepository());
    final endpoint = _providerField(t.settings.provider.baseUrl);
    await tester.enterText(endpoint, 'https://gateway.example.com/v1');
    await tester.tap(find.text(t.settings.format.messages));
    await tester.pumpAndSettle();

    expect(
      tester.widget<EditableText>(endpoint).controller.text,
      'https://gateway.example.com/v1',
    );
  });

  testWidgets('new provider fetches catalog but starts with no added rows', (
    tester,
  ) async {
    final settings = FakeAiSettingsRepository();
    final catalog = FakeModelCatalog();
    await _open(tester, '/me/provider', settings: settings, catalog: catalog);

    await tester.enterText(_providerField(t.settings.provider.name), 'Gateway');
    await tester.enterText(
      _providerField(t.settings.provider.apiKey),
      'sk-test',
    );
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();

    expect(catalog.calls, hasLength(1));
    expect(settings.current.models, hasLength(2));
    expect(settings.current.enabledModels, isEmpty);
    expect(find.text('model-a'), findsNothing);
    expect(find.byKey(const ValueKey('add-model-button')), findsOneWidget);
  });

  testWidgets('new provider saves custom headers and uses them for fetching', (
    tester,
  ) async {
    final settings = FakeAiSettingsRepository();
    final catalog = FakeModelCatalog();
    await _open(tester, '/me/provider', settings: settings, catalog: catalog);

    await tester.enterText(_providerField(t.settings.provider.name), 'Gateway');
    await tester.enterText(
      _providerField(t.settings.provider.apiKey),
      'sk-test',
    );
    await tester.tap(find.byKey(const ValueKey('edit-provider-headers')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-provider-header')));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byKey(const ValueKey('provider-headers-sheet')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(fields.at(0), 'X-Gateway');
    await tester.enterText(fields.at(1), 'mobile');
    await tester.tap(find.byKey(const ValueKey('save-provider-headers')));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();

    expect(settings.current.providers.single.headers, {'X-Gateway': 'mobile'});
    expect(catalog.calls.single.provider.headers, {'X-Gateway': 'mobile'});
  });

  testWidgets('editing provider can remove headers and preserves the rest', (
    tester,
  ) async {
    final settings = FakeAiSettingsRepository(
      apiKeys: const {'p1': 'sk-test'},
      settings: const AiSettings(
        providers: [
          ProviderConfig(
            id: 'p1',
            name: 'Gateway',
            format: ApiFormat.chatCompletions,
            baseUrl: 'https://gw.example.com/v1',
            headers: {'X-Trace': 'old', 'X-Remove': 'remove'},
          ),
        ],
      ),
    );
    await _open(tester, '/me/provider?id=p1', settings: settings);

    await tester.tap(find.byKey(const ValueKey('edit-provider-headers')));
    await tester.pumpAndSettle();
    final sheet = find.byKey(const ValueKey('provider-headers-sheet'));
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).backgroundColor,
      AppGlassTheme.light.bubbleOther,
    );
    await tester.tap(find.byKey(const ValueKey('remove-provider-header-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('remove-provider-header-1')), findsNothing);
    final fields = find.descendant(
      of: sheet,
      matching: find.byType(EditableText),
    );
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(1), 'updated');
    await tester.tap(find.byKey(const ValueKey('save-provider-headers')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();

    expect(settings.current.providers.single.headers, {'X-Trace': 'updated'});
  });

  testWidgets('model chooser searches, checks and batch-adds in a half sheet', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final settings = FakeAiSettingsRepository(
      settings: const AiSettings(
        providers: [_provider],
        models: [
          ModelConfig(providerId: 'p1', modelId: 'model-a'),
          ModelConfig(providerId: 'p1', modelId: 'model-b'),
        ],
      ),
    );
    await _open(tester, '/me/provider?id=p1', settings: settings);

    await tester.tap(find.byKey(const ValueKey('add-model-button')));
    await tester.pumpAndSettle();
    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.backgroundColor, AppGlassTheme.light.bubbleOther);
    final height = tester
        .getSize(find.byKey(const ValueKey('model-chooser')))
        .height;
    expect(height, greaterThan(kPhoneViewport.height * 0.45));
    expect(height, lessThan(kPhoneViewport.height * 0.7));

    await tester.enterText(
      find.byKey(const ValueKey('model-search-input')),
      'MODEL-B',
    );
    await tester.pumpAndSettle();
    expect(find.text('model-a'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('model-option-model-b')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-add-models')));
    await tester.pumpAndSettle();

    expect(settings.current.enabledModels.map((m) => m.modelId), ['model-b']);
    expect(settings.current.resolvedModel?.modelId, 'model-b');
    expect(find.byKey(const ValueKey('model-open-model-b')), findsOneWidget);
  });

  testWidgets('large catalog builds visible rows only and cancel keeps state', (
    tester,
  ) async {
    final settings = FakeAiSettingsRepository(
      settings: AiSettings(
        providers: const [_provider],
        models: [
          for (var i = 0; i < 1000; i++)
            ModelConfig(providerId: 'p1', modelId: 'model-$i'),
        ],
      ),
    );
    await _open(tester, '/me/provider?id=p1', settings: settings);
    await tester.tap(find.byKey(const ValueKey('add-model-button')));
    await tester.pumpAndSettle();

    final list = tester.widget<ListView>(
      find.byKey(const ValueKey('model-selection-list')),
    );
    expect(list.childrenDelegate, isA<SliverChildBuilderDelegate>());
    expect(find.text('model-999'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('model-search-input')),
      'model-999',
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('model-selection-list')),
        matching: find.text('model-999'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('cancel-model-selection')));
    await tester.pumpAndSettle();
    expect(settings.current.enabledModels, isEmpty);
  });

  testWidgets('chooser stays inside a small viewport with the keyboard open', (
    tester,
  ) async {
    final settings = FakeAiSettingsRepository(
      settings: const AiSettings(
        providers: [_provider],
        models: [ModelConfig(providerId: 'p1', modelId: 'gpt-x')],
      ),
    );
    await _open(tester, '/me/provider?id=p1', settings: settings);
    await tester.tap(find.byKey(const ValueKey('add-model-button')));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(960, 1920);
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('model-search-input')), findsOneWidget);
    expect(
      tester.getBottomRight(find.byKey(const ValueKey('model-chooser'))).dy,
      lessThanOrEqualTo(640),
    );
  });

  testWidgets('selection and settings sheets follow dark surfaces', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final settings = FakeAiSettingsRepository(
      settings: const AiSettings(
        providers: [_provider],
        models: [
          ModelConfig(providerId: 'p1', modelId: 'gpt-x', enabled: true),
          ModelConfig(providerId: 'p1', modelId: 'gpt-y'),
        ],
      ),
    );
    await _open(tester, '/me/provider?id=p1', settings: settings);

    await tester.tap(find.byKey(const ValueKey('add-model-button')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).backgroundColor,
      AppGlassTheme.dark.bubbleOther,
    );
    await tester.tap(find.byKey(const ValueKey('cancel-model-selection')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('model-open-gpt-x')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).backgroundColor,
      AppGlassTheme.dark.bubbleOther,
    );
  });

  testWidgets('added row saves capabilities and thinking effort immediately', (
    tester,
  ) async {
    final settings = FakeAiSettingsRepository(
      settings: const AiSettings(
        providers: [_provider],
        models: [
          ModelConfig(providerId: 'p1', modelId: 'gpt-x', enabled: true),
        ],
      ),
    );
    await _open(tester, '/me/provider?id=p1', settings: settings);

    await tester.tap(find.byKey(const ValueKey('model-images-gpt-x')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('model-reasoning-gpt-x')));
    await tester.pumpAndSettle();
    expect(settings.current.models.single.supportsImages, isTrue);
    expect(settings.current.models.single.supportsReasoning, isTrue);
    final effort = tester.widget<GlassSegmentedControl>(
      find.byKey(const ValueKey('model-effort-gpt-x')),
    );
    expect(effort.height, lessThan(kPhoneViewport.height / 20));
    await tester.tap(find.text(t.settings.effort.high));
    await tester.pumpAndSettle();
    expect(
      settings.current.models.single.reasoningEffort,
      ReasoningEffort.high,
    );
  });

  testWidgets('model name opens half sheet to save budgets or remove model', (
    tester,
  ) async {
    final settings = FakeAiSettingsRepository(
      settings: const AiSettings(
        providers: [_provider],
        models: [
          ModelConfig(providerId: 'p1', modelId: 'gpt-x', enabled: true),
        ],
      ),
    );
    await _open(tester, '/me/provider?id=p1', settings: settings);

    await tester.tap(find.byKey(const ValueKey('model-open-gpt-x')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
    final sheetHeight = tester
        .getSize(find.byKey(const ValueKey('model-settings-sheet')))
        .height;
    expect(sheetHeight, lessThan(kPhoneViewport.height * 0.7));
    await tester.enterText(
      _formField(const ValueKey('model-input-tokens')),
      '64000',
    );
    await tester.tap(find.byKey(const ValueKey('save-model-settings')));
    await tester.pumpAndSettle();
    expect(settings.current.models.single.maxInputTokens, 64000);

    await tester.tap(find.byKey(const ValueKey('model-open-gpt-x')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-model-button')));
    await tester.pumpAndSettle();
    expect(find.byType(AppConfirmDialog), findsOneWidget);
    await tester.tap(find.text('Delete model').last);
    await tester.pumpAndSettle();
    expect(settings.current.enabledModels, isEmpty);
    expect(find.byKey(const ValueKey('model-open-gpt-x')), findsNothing);
  });
}
