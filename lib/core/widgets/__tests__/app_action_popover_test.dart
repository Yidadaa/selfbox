import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/testing/icon_finder.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/theme/app_popover_tokens.dart';
import 'package:selfbox/core/theme/message_tokens.dart';
import 'package:selfbox/core/widgets/app_action_popover.dart';
import 'package:selfbox/gen/i18n/strings.g.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('popover is anchored, opaque and dismissible in $brightness', (
      tester,
    ) async {
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
        final box =
            tester.widget<DecoratedBox>(surface).decoration as BoxDecoration;
        expect(box.color, Colors.white);
        expect(box.borderRadius, BorderRadius.circular(MessageTokens.radius));
        expect(box.boxShadow!.single.blurRadius, greaterThanOrEqualTo(32));
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
    });
  }
  testWidgets('sliding across actions updates highlight and releases once', (
    tester,
  ) async {
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
    );
    await tester.longPressAt(const Offset(195, 420));
    await tester.pumpAndSettle();
    final first = tester.getCenter(find.text(t.common.copy));
    final second = tester.getCenter(find.text(t.common.delete));
    final finger = await tester.startGesture(first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_highlightColor(tester, t.common.copy), AppPopoverTokens.highlight);
    await finger.moveTo(second);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_highlightColor(tester, t.common.copy), Colors.transparent);
    expect(
      _highlightColor(tester, t.common.delete),
      AppPopoverTokens.highlight,
    );
    await finger.moveTo(const Offset(24, 420));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_highlightColor(tester, t.common.delete), Colors.transparent);
    await finger.moveTo(second);
    await tester.pump(const Duration(milliseconds: 200));
    await finger.up();
    await tester.pumpAndSettle();
    expect(activated, ['delete']);
  });

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
    expect(_highlightColor(tester, t.common.copy), AppPopoverTokens.highlight);
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
              .widget<AnimatedContainer>(
                find
                    .descendant(
                      of: item,
                      matching: find.byType(AnimatedContainer),
                    )
                    .first,
              )
              .decoration
          as BoxDecoration;
  return decoration.color ?? Colors.transparent;
}
