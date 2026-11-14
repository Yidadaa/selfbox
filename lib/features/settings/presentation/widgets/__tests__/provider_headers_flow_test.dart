import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../pages/__tests__/settings_test_support.dart';

void main() {
  testWidgets('new provider saves custom headers and uses them for fetching', (
    tester,
  ) async {
    final settings = FakeAiSettingsRepository();
    final catalog = FakeModelCatalog();
    await openSettingsPage(
      tester,
      '/me/provider',
      settings: settings,
      catalog: catalog,
    );

    await tester.enterText(settingsField(t.settings.provider.name), 'Gateway');
    await tester.enterText(
      settingsField(t.settings.provider.apiKey),
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
    await openSettingsPage(tester, '/me/provider?id=p1', settings: settings);

    await tester.tap(find.byKey(const ValueKey('edit-provider-headers')));
    await tester.pumpAndSettle();
    final sheet = find.byKey(const ValueKey('provider-headers-sheet'));
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).backgroundColor,
      AppGlassTheme.light.bubbleOther,
    );
    await tester.tap(find.byKey(const ValueKey('remove-provider-header-1')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('remove-provider-header-1')),
      findsNothing,
    );
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
}
