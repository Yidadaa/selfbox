import 'dart:math' as math;
import 'dart:ui';

import 'app_artwork_tokens.dart';
import 'app_spacing.dart';

abstract final class MessageShareTokens {
  static const width = 390.0;
  static const pixelRatio = 3.0;
  static const maxPixels = 12000000;
  static const maxDimension = 16384.0;
  static const artworkSize = AppArtworkTokens.welcome;
  static const artworkOverlap = AppSpacing.xl;
  static const avatarSize = AppSpacing.lg;
  static const captionSize = 10.0;

  // Bound raster memory while retaining the entire laid-out message.
  static double rasterRatio(Size size) => math.min(
    pixelRatio,
    math.min(
      math.sqrt(maxPixels / (size.width * size.height)),
      maxDimension / math.max(size.width, size.height),
    ),
  );
}
