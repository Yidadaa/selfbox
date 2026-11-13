import 'dart:math' as math;

import 'app_spacing.dart';

abstract final class AppArtworkTokens {
  static const double hero = 200;
  static const double feedback = 160;
  static const double welcome = 144;
  static const double welcomeCompact = 96;
  static const double welcomeOverlap = 0.3;
  static const double welcomeAlignment = -0.4;
  static const double logo = 128;
  static const double compact = 72;
  static const int maxDecodeSize = 768;

  static double welcomeSizeFor(
    double viewportWidth, {
    required bool keyboardOpen,
  }) => math
      .min(
        keyboardOpen ? welcomeCompact : welcome,
        viewportWidth -
            2 * AppInsets.pageHorizontal -
            2 * (AppSizes.minTouchTarget + AppSpacing.sm),
      )
      .clamp(0.0, double.infinity);
}
