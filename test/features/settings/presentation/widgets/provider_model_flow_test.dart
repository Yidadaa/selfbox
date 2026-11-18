import 'dart:ui' show CheckedState;

import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/core/theme/sdk_material.dart';
import 'package:selfbox/core/widgets/app_confirm_dialog.dart';
import 'package:selfbox/core/widgets/app_icon.dart';
import 'package:selfbox/core/widgets/app_page_button.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

import '../../../../support/app_widget_tester.dart';
import '../../../../support/fake_ai_settings.dart';
import '../../../../support/icon_finder.dart';
import '../pages/settings_test_support.dart';

Finder _formField(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

FakeAiSettingsRepository _withModels(List<ModelConfig> models) =>
    FakeAiSettingsRepository(
      settings: AiSettings(providers: const [testProvider], models: models),
    );

void main() {
  testWidgets('model chooser searches, checks and batch-adds in a half sheet', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final settings = _withModels(const [
      ModelConfig(providerId: 'p1', modelId: 'model-a'),
      ModelConfig(providerId: 'p1', modelId: 'model-b'),
    ]);
    await openSettingsPage(tester, '/me/provider?id=p1', settings: settings);

    for (final key in ['add-model-button', 'fetch-models-button']) {
      final icon = tester.widget<AppIcon>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(AppIcon),
        ),
      );
      expect(icon.size, AppSizes.iconSm);
    }
    expect(
      tester
          .widget<AppPageButton>(find.byKey(const ValueKey('add-model-button')))
          .label,
      t.settings.provider.addModelAvailable(count: 2),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('fetch-models-button')),
        matching: findAppIcon(AppIcons.download),
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const ValueKey('add-model-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-model-button')));
    await tester.pumpAndSettle();
    final height = tester
        .getSize(find.byKey(const ValueKey('model-chooser')))
        .height;
    final sheetRect = tester.getRect(
      find.byKey(const ValueKey('model-chooser')),
    );
    final headerRect = tester.getRect(
      find.byKey(const ValueKey('model-selection-header')),
    );
    expect(headerRect.left, sheetRect.left);
    expect(headerRect.right, sheetRect.right);
    expect(
      tester.getRect(find.byKey(const ValueKey('confirm-add-models'))).right,
      sheetRect.right - AppSpacing.md,
    );
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
    expect(
      tester
          .widget<AppPageButton>(find.byKey(const ValueKey('add-model-button')))
          .label,
      t.settings.provider.addModelAvailable(count: 1),
    );
  });

  testWidgets('large catalog builds visible rows only and cancel keeps state', (
    tester,
  ) async {
    final settings = _withModels([
      for (var i = 0; i < 1000; i++)
        ModelConfig(providerId: 'p1', modelId: 'model-$i'),
    ]);
    await openSettingsPage(tester, '/me/provider?id=p1', settings: settings);
    await tester.ensureVisible(find.byKey(const ValueKey('add-model-button')));
    await tester.pumpAndSettle();
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
    final settings = _withModels(const [
      ModelConfig(providerId: 'p1', modelId: 'gpt-x'),
    ]);
    await openSettingsPage(tester, '/me/provider?id=p1', settings: settings);
    await tester.ensureVisible(find.byKey(const ValueKey('add-model-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-model-button')));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(960, 1920);
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('model-search-input')), findsOneWidget);
    final sheet = tester.getRect(find.byKey(const ValueKey('model-chooser')));
    for (final key in ['cancel-model-selection', 'confirm-add-models']) {
      final button = tester.getRect(find.byKey(ValueKey(key)));
      expect(button.left, greaterThanOrEqualTo(sheet.left));
      expect(button.right, lessThanOrEqualTo(sheet.right));
      expect(button.height, greaterThanOrEqualTo(48));
    }
    expect(
      tester.getBottomRight(find.byKey(const ValueKey('model-chooser'))).dy,
      lessThanOrEqualTo(640),
    );
  });

  testWidgets('added row saves capabilities and thinking effort immediately', (
    tester,
  ) async {
    final settings = _withModels(const [
      ModelConfig(providerId: 'p1', modelId: 'gpt-x', enabled: true),
    ]);
    await openSettingsPage(tester, '/me/provider?id=p1', settings: settings);

    expect(find.byType(GlassSwitch), findsNothing);
    expect(findAppIcon(AppIcons.unchecked), findsNWidgets(2));
    final images = tester.getRect(
      find.byKey(const ValueKey('model-images-gpt-x')),
    );
    final reasoning = tester.getRect(
      find.byKey(const ValueKey('model-reasoning-gpt-x')),
    );
    expect(reasoning.left - images.right, AppSpacing.md);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('model-images-gpt-x')))
          .getSemanticsData()
          .flagsCollection
          .isChecked,
      CheckedState.isFalse,
    );

    await tester.tap(find.byKey(const ValueKey('model-images-gpt-x')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('model-reasoning-gpt-x')));
    await tester.pumpAndSettle();
    expect(settings.current.models.single.supportsImages, isTrue);
    expect(settings.current.models.single.supportsReasoning, isTrue);
    expect(findAppIcon(AppIcons.checked), findsNWidgets(2));
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('model-images-gpt-x')))
          .getSemanticsData()
          .flagsCollection
          .isChecked,
      CheckedState.isTrue,
    );
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
    final settings = _withModels(const [
      ModelConfig(providerId: 'p1', modelId: 'gpt-x', enabled: true),
    ]);
    await openSettingsPage(tester, '/me/provider?id=p1', settings: settings);

    await tester.tap(find.byKey(const ValueKey('model-open-gpt-x')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(findAppIcon(AppIcons.next), findsWidgets);
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
