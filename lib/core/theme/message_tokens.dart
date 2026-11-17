import 'package:flutter/widgets.dart';

import 'app_radius.dart';
import 'app_spacing.dart';

abstract final class MessageTokens {
  static const pinnedEdgeFadeExtent = AppSpacing.xl;

  static LinearGradient pinnedListFade(double height) {
    final edge = height <= 0
        ? 0.0
        : (pinnedEdgeFadeExtent / height).clamp(0.0, 0.5);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0x00FFFFFF),
        Color(0xFFFFFFFF),
        Color(0xFFFFFFFF),
        Color(0x00FFFFFF),
      ],
      stops: [0, edge, 1 - edge, 1],
    );
  }

  static LinearGradient? pinnedSurfaceGradient(Brightness brightness) =>
      switch (brightness) {
        Brightness.light => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4F4F5), Color(0xFFECEDEF), Color(0xFFE2E4E7)],
          stops: [0, 0.46, 1],
        ),
        Brightness.dark => null,
      };

  static Color? pinnedSurfaceColor(Brightness brightness) =>
      switch (brightness) {
        Brightness.light => const Color(0xFFF0F1F4),
        Brightness.dark => null,
      };

  static Color selectionColor(Brightness brightness) => switch (brightness) {
    Brightness.light => const Color(0x40787880),
    Brightness.dark => const Color(0x50787880),
  };

  static const widthFactor = 0.82;
  static const radius = 20.0;
  static const previewHeightFactor = 0.5;
  static const previewHintHeight = AppSizes.minTouchTarget + AppSpacing.md;
  static Color quoteColor(Brightness brightness) => switch (brightness) {
    Brightness.light => const Color(0xFF0064D2),
    Brightness.dark => const Color(0xFF80BFFF),
  };
  static LinearGradient previewFade(Color color) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [color.withValues(alpha: 0), color, color],
    stops: const [0, AppSpacing.md / previewHintHeight, 1],
  );
  static const tail = 6.0;
  static const bookmarkIconSize = 16.0;
  static const imageWidth = 224.0;
  static const imageHeight = 180.0;
  static const stackInset = 8.0;
  static const stackAngle = 0.1;
  static const imageFramePadding = AppSpacing.xxs / 2;
  static const imageFrameRadius = AppRadius.sm + imageFramePadding;
  static const imageShadowBlur = 24.0;
  static const imageShadowSpread = 1.0;
  static const imageShadowOffset = Offset(0, AppSpacing.xs);
}

const kBubbleImageDecodeWidth = 960;
