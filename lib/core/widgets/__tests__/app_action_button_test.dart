import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_dialog_tokens.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/theme/app_relief_theme.dart';
import 'package:selfbox/core/widgets/app_action_button.dart';

void main() {
  for (final reducedMotion in [false, true]) {
    testWidgets(
      'press cancellation and disabling while held with reducedMotion=$reducedMotion',
      (tester) async {
        final enabled = ValueNotifier(true);
        addTearDown(enabled.dispose);
        var taps = 0;
        await tester.pumpPage(
          ValueListenableBuilder(
            valueListenable: enabled,
            builder: (_, value, _) => MediaQuery(
              data: MediaQueryData(disableAnimations: reducedMotion),
              child: Center(
                child: AppActionButton(
                  label: 'Action',
                  onPressed: value ? () => taps++ : null,
                ),
              ),
            ),
          ),
        );
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Action')),
        );
        await tester.pump(const Duration(milliseconds: 200));
        enabled.value = false;
        await tester.pumpAndSettle();
        await gesture.up();
        await tester.pumpAndSettle();
        expect(taps, 0);
        expect(tester.takeException(), isNull);
        enabled.value = true;
        await tester.pumpAndSettle();
        await tester.tap(find.text('Action'));
        await tester.pumpAndSettle();
        expect(taps, 1);
        expect(tester.binding.hasScheduledFrame, isFalse);
      },
    );
  }

  for (final brightness in Brightness.values) {
    for (final variant in AppActionButtonVariant.values) {
      testWidgets('disabled $variant remains quiet in $brightness', (
        tester,
      ) async {
        await tester.pumpPage(
          Center(
            child: AppActionButton(
              label: 'Action',
              variant: variant,
              onPressed: null,
            ),
          ),
          brightness: brightness,
        );
        final button = tester.widget<TextButton>(find.byType(TextButton));
        final style = button.style;
        final enabled = style?.backgroundColor?.resolve({});
        final disabled = style?.backgroundColor?.resolve({
          WidgetState.disabled,
        });
        expect(disabled?.a, lessThan(enabled?.a ?? 0));
        expect(style?.side?.resolve({WidgetState.disabled}), isA<BorderSide>());
        expect(
          DefaultTextStyle.of(tester.element(find.text('Action'))).style.color,
          style?.foregroundColor?.resolve({WidgetState.disabled}),
        );
      });
    }
  }

  testWidgets('shared action buttons use rounded low-contrast surfaces', (
    tester,
  ) async {
    await tester.pumpPage(
      const Center(
        child: AppActionButton(
          label: 'Save',
          onPressed: _noop,
          variant: AppActionButtonVariant.primary,
        ),
      ),
      brightness: Brightness.light,
    );

    final button = tester.widget<TextButton>(find.byType(TextButton));
    final shape = button.style?.shape?.resolve({});
    final side = button.style?.side?.resolve({});
    expect(shape, AppDialogTokens.actionShape);
    expect(tester.getSize(find.byType(TextButton)).height, 48);
    expect(side, isA<BorderSide>());
    expect(button.style?.backgroundColor?.resolve({}), isNotNull);
    final decoration = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(TextButton),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<ShapeDecoration>()
        .first;
    final gradient = decoration.gradient! as LinearGradient;
    expect(gradient.colors.first, isNot(gradient.colors.last));
    expect(
      decoration.shape,
      AppDialogTokens.actionShape.copyWith(
        side: AppReliefTheme.of(tester.element(find.byType(TextButton))).border,
      ),
    );
  });

  testWidgets('destructive and secondary variants follow the active theme', (
    tester,
  ) async {
    await tester.pumpPage(
      const Column(
        children: [
          AppActionButton(label: 'Cancel', onPressed: _noop),
          AppActionButton(
            label: 'Delete',
            onPressed: _noop,
            variant: AppActionButtonVariant.destructive,
          ),
        ],
      ),
    );

    final buttons = tester.widgetList<TextButton>(find.byType(TextButton));
    expect(buttons, hasLength(2));
    final secondary = buttons.first;
    final destructive = buttons.last;
    expect(
      secondary.style?.foregroundColor?.resolve({}),
      AppGlassTheme.dark.foreground,
    );
    expect(
      destructive.style?.foregroundColor?.resolve({}),
      AppGlassTheme.dark.dialogDestructive,
    );
    expect(
      secondary.style?.backgroundColor?.resolve({}),
      AppGlassTheme.dark.dialogActionFill,
    );
    expect(
      destructive.style?.backgroundColor?.resolve({}),
      AppGlassTheme.dark.dialogDestructiveFill,
    );
    expect(destructive.style?.side?.resolve({}), isA<BorderSide>());
  });

  testWidgets('icon action buttons keep the shared rounded hit target', (
    tester,
  ) async {
    await tester.pumpPage(
      const Center(
        child: AppActionIconButton(
          tooltip: 'Close',
          icon: AppIcons.close,
          onPressed: _noop,
        ),
      ),
      brightness: Brightness.light,
    );

    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(tester.getSize(find.byType(IconButton)), const Size(48, 48));
    expect(button.style?.shape?.resolve({}), AppDialogTokens.actionShape);
    expect(button.style?.side?.resolve({}), isA<BorderSide>());
    expect(button.style?.backgroundColor?.resolve({}), isNotNull);
  });
}

void _noop() {}
