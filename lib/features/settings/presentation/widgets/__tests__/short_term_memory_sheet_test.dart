import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/error/app_failure.dart';
import 'package:selfbox/core/router/app_router.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/fake_ai_settings.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_spacing.dart';
import 'package:selfbox/features/settings/domain/models/ai_settings.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

const _configured = AiSettings(
  models: [ModelConfig(providerId: 'p', modelId: '128k', enabled: true)],
);
const _sliderKey = ValueKey('short-term-memory-slider');
const _tokensKey = ValueKey('short-term-memory-tokens');
const _saveKey = ValueKey('short-term-memory-save');
const _cancelKey = ValueKey('short-term-memory-cancel');

Future<void> _open(
  WidgetTester tester,
  FakeAiSettingsRepository repository, {
  AppLocale locale = AppLocale.en,
  Brightness brightness = Brightness.light,
}) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final container = await tester.pumpApp(settings: repository, locale: locale);
  container.read(appRouterProvider).go('/me/providers');
  await tester.pumpAndSettle();
  await tester.tap(find.text(t.settings.shortTermMemory));
  await tester.pumpAndSettle();
}

class _FailingSettings extends FakeAiSettingsRepository {
  _FailingSettings() : super(settings: _configured);

  bool failSave = true;

  @override
  TaskEither<AppFailure, Unit> save(AiSettings settings) => failSave
      ? TaskEither.left(const AppFailure.database(message: 'write failed'))
      : super.save(settings);
}

Future<void> _dragToMiddle(WidgetTester tester) async {
  final bounds = tester.getRect(find.byKey(_sliderKey));
  await tester.dragFrom(
    bounds.center - const Offset(64, 0),
    const Offset(64, 0),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    for (final locale in AppLocale.values) {
      testWidgets(
        'slider and live estimate use two rows in ${brightness.name}/${locale.name}',
        (tester) async {
          final repository = FakeAiSettingsRepository(settings: _configured);
          await _open(
            tester,
            repository,
            brightness: brightness,
            locale: locale,
          );
          final slider = tester.widget<GlassSlider>(find.byKey(_sliderKey));
          expect(slider.min, 10);
          expect(slider.max, 60);
          expect(slider.divisions, 50);
          expect(slider.value, 20);
          expect(find.text('25,600'), findsOneWidget);
          final number = tester.widget<Text>(find.byKey(_tokensKey));
          expect(number.style?.fontSize, greaterThanOrEqualTo(56));
          final cancel = tester.getRect(find.byKey(_cancelKey));
          final save = tester.getRect(find.byKey(_saveKey));
          expect(cancel.width, closeTo(save.width, 0.01));
          expect(cancel.top, save.top);
          expect(cancel.right, lessThan(save.left));
          expect(cancel.height, greaterThanOrEqualTo(AppSizes.minTouchTarget));
          expect(save.height, cancel.height);
          expect(
            cancel.top,
            greaterThan(tester.getBottomLeft(find.byKey(_tokensKey)).dy),
          );
          expect(
            tester.getBottomLeft(find.byKey(_sliderKey)).dy,
            lessThanOrEqualTo(tester.getTopLeft(find.byKey(_tokensKey)).dy),
          );
          expect(
            tester.getSize(find.byKey(_sliderKey)).height,
            greaterThanOrEqualTo(AppSizes.minTouchTarget),
          );
          expect(
            tester
                .widget<BottomSheet>(find.byType(BottomSheet))
                .backgroundColor,
            brightness == Brightness.dark
                ? AppGlassTheme.dark.bubbleOther
                : AppGlassTheme.light.bubbleOther,
          );

          await _dragToMiddle(tester);
          final percent = tester
              .widget<GlassSlider>(find.byKey(_sliderKey))
              .value
              .round();
          expect(percent, 35);
          expect(
            tester
                .getSemantics(
                  find.byKey(const ValueKey('short-term-memory-semantics')),
                )
                .getSemanticsData()
                .value,
            '35%',
          );
          expect(find.text('44,800'), findsOneWidget);
          expect(repository.current.shortTermMemoryPercent, 20);
          await tester.tap(find.byKey(_saveKey));
          await tester.pumpAndSettle();
          expect(repository.current.shortTermMemoryPercent, 35);
          expect(find.byType(BottomSheet), findsNothing);
          expect(find.text('35%'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('cancel discards the draft percentage', (tester) async {
    final repository = FakeAiSettingsRepository(settings: _configured);
    await _open(tester, repository);
    final bounds = tester.getRect(find.byKey(_sliderKey));
    await tester.dragFrom(bounds.center, Offset(bounds.width / 2, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<GlassSlider>(find.byKey(_sliderKey)).value, 60);
    await tester.tap(find.byKey(_cancelKey));
    await tester.pumpAndSettle();
    expect(repository.current.shortTermMemoryPercent, 20);
  });

  testWidgets(
    'estimate follows the current model context while sheet is open',
    (tester) async {
      final repository = FakeAiSettingsRepository(settings: _configured);
      await _open(tester, repository);
      await repository
          .save(
            _configured.copyWith(
              models: [
                _configured.models.single.copyWith(maxInputTokens: 64000),
              ],
            ),
          )
          .run();
      await tester.pumpAndSettle();
      expect(find.text('12,800'), findsOneWidget);
      await repository.save(const AiSettings()).run();
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(t.common.notSet),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('percentage remains configurable before a model is added', (
    tester,
  ) async {
    final repository = FakeAiSettingsRepository();
    await _open(tester, repository);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(t.common.notSet),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(_saveKey));
    await tester.pumpAndSettle();
    expect(repository.current.shortTermMemoryPercent, 20);
  });

  testWidgets('failed save retains the draft and supports retry', (
    tester,
  ) async {
    final repository = _FailingSettings();
    await _open(tester, repository);
    await _dragToMiddle(tester);
    await tester.tap(find.byKey(_saveKey));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(repository.current.shortTermMemoryPercent, 20);
    expect(tester.widget<GlassSlider>(find.byKey(_sliderKey)).value, 35);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    repository.failSave = false;
    await tester.tap(find.byKey(_saveKey));
    await tester.pumpAndSettle();
    expect(repository.current.shortTermMemoryPercent, 35);
    expect(find.byType(BottomSheet), findsNothing);
  });

  for (final locale in AppLocale.values) {
    testWidgets(
      'narrow sheet keeps title, actions and slider inside viewport in ${locale.name}',
      (tester) async {
        await _open(
          tester,
          FakeAiSettingsRepository(settings: _configured),
          locale: locale,
        );
        tester.view.physicalSize = const Size(280 * 3, 844 * 3);
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();
        for (final key in [_sliderKey, _tokensKey, _cancelKey, _saveKey]) {
          final bounds = tester.getRect(find.byKey(key));
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(280));
        }
        final title = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(t.settings.shortTermMemory),
        );
        expect(
          tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
          isFalse,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
