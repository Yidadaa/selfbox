import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/features/settings/presentation/pages/model_page.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import 'settings_test_support.dart';

void main() {
  group('ModelPage', () {
    final base = FakeAiSettingsRepository(
      settings: const AiSettings(
        providers: [testProvider],
        models: [ModelConfig(providerId: 'p1', modelId: 'gpt-x')],
      ),
    );

    testWidgets('edits capabilities and budgets', (tester) async {
      final settings = FakeAiSettingsRepository(settings: base.current);
      await openSettingsPage(
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
      await tester.enterText(
        settingsField(t.settings.model.outputTokens),
        '16000',
      );
      await tester.tap(find.text(t.common.save));
      await tester.pumpAndSettle();

      final model = settings.current.models.single;
      expect(model.supportsImages, isTrue);
      expect(model.supportsReasoning, isTrue);
      expect(model.reasoningEffort, ReasoningEffort.high);
      expect(model.maxOutputTokens, 16000);
      expect(find.byType(ModelPage), findsNothing);
      await settleSettingsToasts(tester);
    });

    testWidgets('rejects non-numeric and too-small budgets', (tester) async {
      final settings = FakeAiSettingsRepository(settings: base.current);
      await openSettingsPage(
        tester,
        '/me/model?provider=p1&model=gpt-x',
        settings: settings,
      );

      await tester.enterText(
        settingsField(t.settings.model.outputTokens),
        '12',
      );
      await tester.enterText(
        settingsField(t.settings.model.inputTokens),
        'abc',
      );
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
      await openSettingsPage(tester, '/me/model?provider=p1&model=nope');
      final label = find.text(t.settings.errors.generic);
      expect(label, findsOneWidget);
      expect(find.byIcon(Icons.memory_rounded), findsNothing);
      expect(
        find.ancestor(of: label, matching: find.byType(GlassContainer)),
        findsNothing,
      );
    });
  });
}
