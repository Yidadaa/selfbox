import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/theme/message_share_tokens.dart';

void main() {
  test('raster budget bounds both area and the longest dimension', () {
    for (final size in [
      const Size(390, 800),
      const Size(390, 8000),
      const Size(390, 30000),
    ]) {
      final ratio = MessageShareTokens.rasterRatio(size);
      expect(
        size.width * size.height * ratio * ratio,
        lessThanOrEqualTo(MessageShareTokens.maxPixels + 1),
      );
      expect(
        size.height * ratio,
        lessThanOrEqualTo(MessageShareTokens.maxDimension),
      );
    }
  });
}
