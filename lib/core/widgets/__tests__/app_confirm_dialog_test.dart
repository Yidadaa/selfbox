import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/widgets/app_confirm_dialog.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('$brightness opaque dialog follows the app layout', (
      tester,
    ) async {
      await tester.pumpPage(
        AppConfirmDialog(
          title: 'Delete everything?',
          secondaryLabel: 'Cancel',
          primaryLabel: 'Delete',
          destructive: true,
          onPrimary: () {},
        ),
        brightness: brightness,
      );

      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      final glass = AppGlassTheme.of(brightness);
      expect(dialog.backgroundColor, glass.bubbleOther);
      expect(
        tester.widget<Text>(find.text('Delete everything?')).style?.color,
        glass.onBubbleOther,
      );
      if (brightness == Brightness.dark) {
        expect(dialog.backgroundColor!.computeLuminance(), lessThan(0.15));
      }
      expect(
        dialog.shape,
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(34)),
        ),
      );
      final surface = tester.getRect(
        find
            .ancestor(
              of: find.text('Delete everything?'),
              matching: find.byType(Material),
            )
            .first,
      );
      final title = tester.getRect(find.text('Delete everything?'));
      final secondary = tester.getRect(
        find.ancestor(
          of: find.text('Cancel'),
          matching: find.byType(TextButton),
        ),
      );
      final primary = tester.getRect(
        find.ancestor(
          of: find.text('Delete'),
          matching: find.byType(TextButton),
        ),
      );
      expect(surface.width, 320);
      expect(title.left - surface.left, 32);
      expect(title.top - surface.top, 24);
      expect(secondary.height, 48);
      expect(primary.height, 48);
      expect(secondary.width, primary.width);
      expect(primary.left - secondary.right, 8);
      expect(secondary.left - surface.left, 16);
      expect(surface.right - primary.right, 16);
      expect(surface.bottom - primary.bottom, 16);
      for (final button in tester.widgetList<TextButton>(
        find.byType(TextButton),
      )) {
        expect(button.style?.shape?.resolve({}), const StadiumBorder());
        expect(
          button.style?.backgroundColor?.resolve({}),
          glass.dialogActionFill,
        );
      }
    });
  }

  testWidgets('large labels stack without clipping on a narrow screen', (
    tester,
  ) async {
    await tester.pumpPage(
      AppConfirmDialog(
        title: 'Delete all messages, photos and settings?',
        secondaryLabel: 'Cancel',
        primaryLabel: 'Delete all data',
        onPrimary: () {},
      ),
    );
    tester.view.physicalSize = const Size(280 * 3, 844 * 3);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    final secondary = tester.getRect(
      find.ancestor(of: find.text('Cancel'), matching: find.byType(TextButton)),
    );
    final primary = tester.getRect(
      find.ancestor(
        of: find.text('Delete all data'),
        matching: find.byType(TextButton),
      ),
    );
    final label = tester.getRect(find.text('Delete all data'));
    expect(primary.top - secondary.bottom, 8);
    expect(primary.width, secondary.width);
    expect(label.left, greaterThanOrEqualTo(primary.left));
    expect(label.right, lessThanOrEqualTo(primary.right));
    expect(label.bottom, lessThanOrEqualTo(primary.bottom));
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('$brightness action dialog uses the owned opaque surface', (
      tester,
    ) async {
      var copied = false;
      var deleted = false;
      await tester.pumpPage(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AppActionDialog(
                title: 'Message actions',
                cancelLabel: 'Cancel',
                actions: [
                  AppDialogAction(
                    label: 'Copy',
                    onPressed: () => copied = true,
                  ),
                  AppDialogAction(
                    label: 'Delete',
                    destructive: true,
                    onPressed: () => deleted = true,
                  ),
                ],
              ),
            ),
            child: const Text('Open'),
          ),
        ),
        brightness: brightness,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      expect(dialog.backgroundColor, AppGlassTheme.of(brightness).bubbleOther);
      expect(
        dialog.shape,
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(34)),
        ),
      );
      expect(find.text('Message actions'), findsOneWidget);
      expect(find.byType(TextButton), findsNWidgets(4));
      final copy = tester.getRect(
        find.ancestor(of: find.text('Copy'), matching: find.byType(TextButton)),
      );
      final delete = tester.getRect(
        find.ancestor(
          of: find.text('Delete'),
          matching: find.byType(TextButton),
        ),
      );
      final cancel = tester.getRect(
        find.ancestor(
          of: find.text('Cancel'),
          matching: find.byType(TextButton),
        ),
      );
      expect(copy.height, 48);
      expect(delete.height, 48);
      expect(cancel.height, 48);
      expect(delete.top - copy.bottom, 8);
      expect(cancel.top - delete.bottom, 8);
      expect(copy.width, delete.width);
      expect(delete.width, cancel.width);
      expect(
        tester.widget<Text>(find.text('Delete')).style?.color,
        AppGlassTheme.of(brightness).dialogDestructive,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(copied, isFalse);
      expect(deleted, isFalse);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(copied, isTrue);
      expect(deleted, isFalse);
    });
  }
}
