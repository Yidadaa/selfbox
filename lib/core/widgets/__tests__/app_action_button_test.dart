import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/widgets/app_action_button.dart';

void main() {
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
    expect(shape, const StadiumBorder());
    expect(tester.getSize(find.byType(TextButton)).height, 48);
    expect(side?.width, 1);
    expect(side?.color.a, lessThanOrEqualTo(0.4));
    expect(button.style?.backgroundColor?.resolve({}), isNotNull);
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
    expect(destructive.style?.side?.resolve({})?.color.a, lessThan(0.4));
  });

  testWidgets('icon action buttons keep the shared rounded hit target', (
    tester,
  ) async {
    await tester.pumpPage(
      const Center(
        child: AppActionIconButton(
          tooltip: 'Close',
          icon: Icons.close_rounded,
          onPressed: _noop,
        ),
      ),
      brightness: Brightness.light,
    );

    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(tester.getSize(find.byType(IconButton)), const Size(48, 48));
    expect(button.style?.shape?.resolve({}), const StadiumBorder());
    expect(button.style?.side?.resolve({})?.color.a, lessThanOrEqualTo(0.4));
    expect(button.style?.backgroundColor?.resolve({}), isNotNull);
  });
}

void _noop() {}
