import 'package:flutter/widgets.dart';

import 'app_radius.dart';
import 'app_spacing.dart';

abstract final class MessageTokens {
  static Color selectionColor(Brightness brightness) => switch (brightness) {
    Brightness.light => const Color(0x40787880),
    Brightness.dark => const Color(0x50787880),
  };

  static const widthFactor = 0.82;
  static const radius = 20.0;
  static const tail = 6.0;
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

const kBubbleImageDecodeWidth = 720;
