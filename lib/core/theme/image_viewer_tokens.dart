import 'package:flutter/painting.dart';

import 'app_glass_theme.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

abstract final class ImageViewerTokens {
  static const canvas = Color(0xFF080B12);
  static final foreground = AppGlassTheme.dark.foreground;
  static final thumbnailFill = AppGlassTheme.dark.bubbleOther;
  static const thumbnailRadius = AppRadius.sm;
  static const thumbnailBorder = 2.0;
  static const thumbnailExtent = AppSizes.attachmentThumbnail + AppSpacing.xs;
  static const maxZoom = 5.0;
  static const doubleTapZoom = 3.0;
  static const zoomTolerance = 1.001;

  static const controlShadow = Shadow(
    color: canvas,
    blurRadius: 4,
    offset: Offset(0, 1),
  );
  static const selectionShadow = BoxShadow(
    color: canvas,
    blurRadius: 4,
    spreadRadius: 1,
  );
}
