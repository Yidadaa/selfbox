import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/theme/app_dialog_tokens.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';
import 'package:selfbox/core/theme/app_relief_theme.dart';

double _contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return x > y ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    test('opaque relief keeps readable gradients in $brightness', () {
      final glass = AppGlassTheme.of(brightness);
      final relief = AppReliefTheme.fromGlass(glass, brightness);
      expect(relief.border.width, lessThanOrEqualTo(1));
      expect(relief.border.color.a, lessThan(0.15));
      for (final color in relief.surfaceGradient.colors) {
        expect(color.a, 1);
        expect(
          _contrast(color, glass.onBubbleOther),
          greaterThanOrEqualTo(4.5),
        );
      }
      for (final (fill, foreground, primary) in [
        (glass.accent, glass.onAccent, true),
        (glass.dialogActionFill, glass.foreground, false),
        (glass.dialogDestructiveFill, glass.dialogDestructive, false),
      ]) {
        for (final pressed in [false, true]) {
          final decoration = relief.actionDecoration(
            AppDialogTokens.actionShape,
            fill,
            disabled: false,
            pressed: pressed,
            primary: primary,
          );
          final gradient = decoration.gradient! as LinearGradient;
          for (final color in gradient.colors) {
            expect(color.a, 1);
            expect(_contrast(color, foreground), greaterThanOrEqualTo(4.5));
          }
        }
      }
      expect(relief.lerp(null, 0.5), same(relief));
      expect(relief.copyWith().top, relief.top);
    });
  }

  test('sheet top corners follow the exact Liquid superellipse path', () {
    const rect = Rect.fromLTWH(0, 0, 320, 220);
    final dialog = AppDialogTokens.dialogShape.getOuterPath(rect);
    final sheet = AppDialogTokens.sheetShape.getOuterPath(rect);
    for (var y = 0.5; y < AppDialogTokens.radius; y++) {
      for (var x = 0.5; x < rect.width; x++) {
        expect(sheet.contains(Offset(x, y)), dialog.contains(Offset(x, y)));
      }
    }
    expect(
      AppDialogTokens.actionShape.borderRadius,
      AppDialogTokens.radius - 16,
    );
  });
}
