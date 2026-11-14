import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/theme/app_ai_tokens.dart';

void main() {
  for (final brightness in Brightness.values) {
    test('$brightness AI gradient stays vivid within red to blue hues', () {
      final colors = AppAiTokens.contentColors(brightness);
      expect(colors.length, greaterThanOrEqualTo(3));
      for (final color in colors) {
        final hsv = HSVColor.fromColor(color);
        expect(hsv.hue >= 210 || hsv.hue <= 15, isTrue);
        expect(hsv.saturation, greaterThanOrEqualTo(0.6));
        expect(hsv.value, greaterThanOrEqualTo(0.75));
      }
      expect(HSVColor.fromColor(colors.first).hue, greaterThanOrEqualTo(330));
      expect(HSVColor.fromColor(colors.last).hue, inInclusiveRange(210, 260));
    });
  }
}
