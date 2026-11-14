import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/icon_finder.dart';
import 'package:selfbox/core/theme/app_effects.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/theme/app_popover_tokens.dart';
import 'package:selfbox/core/widgets/app_action_popover.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'popover is compact glass, anchored and dismissible in $brightness',
      (tester) async {
        var copied = 0;
        await tester.pumpPage(
          AppPopoverRegion(
            actions: [
              AppPopoverAction(
                label: t.common.copy,
                icon: AppIcons.copy,
                onPressed: () => copied++,
              ),
            ],
            builder: (_, open) => GestureDetector(
              onLongPressStart: (details) => open(details.globalPosition),
              child: const ColoredBox(color: Colors.blue),
            ),
          ),
          brightness: brightness,
        );
        for (final anchor in [const Offset(24, 70), const Offset(360, 760)]) {
          await tester.longPressAt(anchor);
          await tester.pumpAndSettle();
          final surface = find.byKey(const ValueKey('app-popover-surface'));
          final glass = tester.widget<GlassContainer>(surface);
          expect(
            glass.shape,
            const LiquidRoundedSuperellipse(borderRadius: 18),
          );
          expect(tester.getSize(surface).width, 136);
          expect(
            tester.getTopLeft(findAppIcon(AppIcons.copy)).dx -
                tester.getTopLeft(surface).dx,
            20,
          );
          expect(
            find.descendant(of: surface, matching: find.byType(Scrollable)),
            findsNothing,
          );
          final label = tester.widget<Text>(find.text(t.common.copy));
          expect(label.style?.fontSize, 12);
          expect(
            tester
                .getSize(find.byKey(ValueKey('popover-item-${t.common.copy}')))
                .height,
            44,
          );
          expect(findAppIcon(AppIcons.copy), findsOneWidget);
          expect(find.byType(Dialog), findsNothing);
          final rect = tester.getRect(surface);
          expect(rect.left, greaterThanOrEqualTo(16));
          expect(rect.right, lessThanOrEqualTo(374));
          expect(rect.top, greaterThanOrEqualTo(47));
          expect(rect.bottom, lessThanOrEqualTo(810));
          await tester.tapAt(const Offset(195, 420));
          await tester.pumpAndSettle();
          expect(surface, findsNothing);
        }
        await tester.longPressAt(const Offset(195, 420));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.common.copy));
        await tester.pumpAndSettle();
        expect(copied, 1);
        expect(find.byType(AppActionPopover), findsNothing);
        await tester.longPressAt(const Offset(195, 420));
        await tester.pumpAndSettle();
        await Navigator.of(tester.element(find.byType(AppPopoverRegion)))
            .maybePop();
        await tester.pumpAndSettle();
        expect(find.byType(AppActionPopover), findsNothing);
        expect(copied, 1);
        tester.view.physicalSize = const Size(280 * 3, 640 * 3);
        tester.view.viewInsets = const FakeViewPadding(bottom: 250 * 3);
        await tester.pumpAndSettle();
        await tester.longPressAt(const Offset(250, 300));
        await tester.pumpAndSettle();
        final compact = tester.getRect(
          find.byKey(const ValueKey('app-popover-surface')),
        );
        expect(compact.left, greaterThanOrEqualTo(16));
        expect(compact.right, lessThanOrEqualTo(264));
        expect(compact.bottom, lessThanOrEqualTo(390));
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final brightness in Brightness.values) {
    for (final quality in GlassQuality.values) {
      testWidgets(
        'popover uses chrome tint with $quality rendering in $brightness',
        (tester) async {
          await tester.pumpPage(
            AppEffects(
              quality: quality,
              animationsEnabled: false,
              child: AppPopoverRegion(
                actions: [
                  AppPopoverAction(
                    label: t.common.copy,
                    icon: AppIcons.copy,
                    onPressed: () {},
                  ),
                ],
                builder: (_, open) => GestureDetector(
                  onLongPressStart: (details) => open(details.globalPosition),
                  child: const ColoredBox(color: Colors.blue),
                ),
              ),
            ),
            brightness: brightness,
          );
          await tester.longPressAt(const Offset(195, 420));
          await tester.pumpAndSettle();
          final surface = tester.widget<GlassContainer>(
            find.byKey(const ValueKey('app-popover-surface')),
          );
          final theme = AppGlassTheme.of(brightness);
          expect(surface.settings?.glassColor, theme.chromeTint);
          expect(surface.settings?.blur, theme.chromeBlur);
          expect(surface.useOwnLayer, isTrue);
          expect(
            tester
                .widget<GlassContainer>(
                  find.byKey(const ValueKey('app-popover-surface')),
                )
                .quality,
            quality == GlassQuality.minimal
                ? GlassQuality.minimal
                : GlassQuality.standard,
          );
        },
      );
    }
  }
  for (final brightness in Brightness.values) {
    testWidgets(
      'sliding across actions updates highlight and releases once in $brightness',
      (tester) async {
        final activated = <String>[];
        await tester.pumpPage(
          AppPopoverRegion(
            actions: [
              AppPopoverAction(
                label: t.common.copy,
                icon: AppIcons.copy,
                onPressed: () => activated.add('copy'),
              ),
              AppPopoverAction(
                label: t.common.delete,
                icon: AppIcons.delete,
                onPressed: () => activated.add('delete'),
              ),
            ],
            builder: (_, open) => GestureDetector(
              onLongPressStart: (details) => open(details.globalPosition),
              child: const ColoredBox(color: Colors.blue),
            ),
          ),
          brightness: brightness,
        );
        await tester.longPressAt(const Offset(195, 420));
        await tester.pumpAndSettle();
        final first = tester.getCenter(find.text(t.common.copy));
        final second = tester.getCenter(find.text(t.common.delete));
        final finger = await tester.startGesture(first);
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          _highlightColor(tester, t.common.copy),
          AppPopoverTokens.highlight(brightness),
        );
        await finger.moveTo(second);
        await tester.pump();
        expect(_highlightColor(tester, t.common.copy), Colors.transparent);
        expect(
          _highlightColor(tester, t.common.delete),
          AppPopoverTokens.highlight(brightness),
        );
        await finger.moveTo(const Offset(24, 420));
        await tester.pump(const Duration(milliseconds: 200));
        expect(_highlightColor(tester, t.common.delete), Colors.transparent);
        await finger.moveTo(second);
        await tester.pump(const Duration(milliseconds: 200));
        await finger.up();
        await tester.pumpAndSettle();
        expect(activated, ['delete']);
      },
    );
  }
  testWidgets('the opening long press can glide into a menu action', (
    tester,
  ) async {
    var activated = false;
    await tester.pumpPage(
      AppPopoverRegion(
        actions: [
          AppPopoverAction(
            label: t.common.copy,
            icon: AppIcons.copy,
            onPressed: () => activated = true,
          ),
        ],
        builder: (_, open) => GestureDetector(
          onLongPressStart: (details) => open(details.globalPosition),
          child: const ColoredBox(color: Colors.blue),
        ),
      ),
    );
    final finger = await tester.startGesture(const Offset(195, 420));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 200));
    final copy = tester.getCenter(find.text(t.common.copy));
    await finger.moveTo(copy);
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      _highlightColor(tester, t.common.copy),
      AppPopoverTokens.highlight(Brightness.dark),
    );
    await finger.up();
    await tester.pumpAndSettle();
    expect(activated, isTrue);
    expect(find.byType(AppActionPopover), findsNothing);
  });
}

Color _highlightColor(WidgetTester tester, String label) {
  final item = find.ancestor(
    of: find.text(label),
    matching: find.byKey(ValueKey('popover-item-$label')),
  );
  final decoration =
      tester
              .widget<Container>(
                find
                    .descendant(of: item, matching: find.byType(Container))
                    .first,
              )
              .decoration
          as ShapeDecoration;
  return decoration.color ?? Colors.transparent;
}
