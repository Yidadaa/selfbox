import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_dialog_tokens.dart';
import 'package:selfbox/core/theme/app_relief_theme.dart';
import 'package:selfbox/core/widgets/app_action_button.dart';
import 'package:selfbox/core/widgets/app_modal_surface.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'sheet uses static relief and returns its result in $brightness',
      (tester) async {
        String? result;
        await tester.pumpPage(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showAppBottomSheet<String>(
                  context: context,
                  builder: (context) => SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: AppActionButton(
                        label: 'Save',
                        onPressed: () => Navigator.of(context).pop('saved'),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
          brightness: brightness,
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
        expect(sheet.shape, AppDialogTokens.sheetShape);
        final modal = find.byType(AppModalSurface);
        final boxes = tester.widgetList<DecoratedBox>(
          find.descendant(of: modal, matching: find.byType(DecoratedBox)),
        );
        final fill = boxes.first.decoration as ShapeDecoration;
        expect(
          fill.gradient,
          AppReliefTheme.of(tester.element(modal)).surfaceGradient,
        );
        expect(fill.shadows, hasLength(2));
        expect(
          find.descendant(of: modal, matching: find.byType(BackdropFilter)),
          findsNothing,
        );
        expect(tester.binding.hasScheduledFrame, isFalse);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(result, 'saved');
        expect(find.byType(BottomSheet), findsNothing);
      },
    );
  }
}
