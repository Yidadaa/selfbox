import 'package:selfbox/core/theme/sdk_material.dart';

abstract final class OnboardingTokens {
  static const double inactiveProgressAlpha = 0.3;
  static Color progressForeground(ThemeData theme) =>
      theme.colorScheme.onSurface;
  static const double maxWidth = 480;
  static const double artwork = 240;
  static const double compactArtwork = 96;
  static const double avatar = 128;
  static const double progressWidth = 20;
  static const double activeProgressWidth = 32;
  static const double progressHeight = 4;
  static const Offset entryOffset = Offset(0, 0.05);
  static const double entryScale = 0.97;
}
