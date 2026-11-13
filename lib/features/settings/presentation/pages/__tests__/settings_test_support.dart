import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/core/theme/app_radius.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';

const testProvider = ProviderConfig(
  id: 'p1',
  name: 'My Gateway',
  format: ApiFormat.chatCompletions,
  baseUrl: 'https://gw.example.com/v1',
);

const otherTestProvider = ProviderConfig(
  id: 'p2',
  name: 'Other Gateway',
  format: ApiFormat.responses,
  baseUrl: 'https://other.example.com/v1',
);

Future<ProviderContainer> openSettingsPage(
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
Future<void> settleSettingsToasts(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

Finder settingsField(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
  matching: find.byType(EditableText),
);

void expectLiquidSections(WidgetTester tester, int count) {
  final sections = tester.widgetList<GlassGroupedSection>(
    find.byType(GlassGroupedSection),
  );
  expect(sections, hasLength(count));
  for (final section in sections) {
    expect(section.surfaceStyle, GlassSurfaceStyle.glass);
    expect(section.quality, GlassQuality.standard);
    expect(
      section.shape,
      const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
    );
  }
}

void expectLiquidFormCard(WidgetTester tester, String fieldLabel) {
  final label = find.text(fieldLabel);
  final card = tester.widget<GlassContainer>(
    find.ancestor(of: label, matching: find.byType(GlassContainer)).first,
  );
  expect(card.quality, GlassQuality.standard);
  expect(
    card.shape,
    const LiquidRoundedSuperellipse(borderRadius: AppRadius.lg),
  );
  expect(
    find.ancestor(of: label, matching: find.byType(AdaptiveGlass)),
    findsWidgets,
  );
}
