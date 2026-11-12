import 'app_radius.dart';
import 'app_spacing.dart';

abstract final class MessageTokens {
  static const widthFactor = 0.82;
  static const radius = 20.0;
  static const tail = 6.0;
  static const imageWidth = 224.0;
  static const imageHeight = 180.0;
  static const stackInset = 8.0;
  static const stackAngle = 0.035;
  static const imageFramePadding = AppSpacing.xxs;
  static const imageFrameRadius = AppRadius.sm + imageFramePadding;
}

const kBubbleImageDecodeWidth = 720;
