import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/testing/app_widget_tester.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/widgets/app_canvas.dart';

void main() {
  group('AppCanvas', () {
    for (final brightness in Brightness.values) {
      testWidgets('paints the $brightness canvas gradient full-bleed', (
        tester,
      ) async {
        await tester.pumpPage(const AppCanvas(), brightness: brightness);

        final box = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(AppCanvas),
            matching: find.byType(DecoratedBox),
          ),
        );
        final gradient =
            (box.decoration as BoxDecoration).gradient as LinearGradient;
        expect(gradient.colors, AppGlassTheme.of(brightness).canvasGradient);
        expect(gradient.begin, Alignment.topLeft);
        expect(tester.getSize(find.byType(AppCanvas)), kPhoneViewport);
        if (brightness == Brightness.light) {
          expect(gradient.colors.last, const Color(0xFFF7EDE4));
        }
      });
    }
  });
}
