import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/theme/app_glass_theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    test(
      '$brightness glass uses reduced blur with compensated chrome tint',
      () {
        final glass = AppGlassTheme.of(brightness);
        expect(glass.chromeBlur, 12);
        expect(glass.surfaceBlur, 8);
        expect(
          glass.chromeTint,
          brightness == Brightness.dark
              ? const Color(0xB7111827)
              : const Color(0xC0FFFFFF),
        );
      },
    );
  }
}
