import 'package:flutter/animation.dart';

abstract final class AppMotion {
  static const double pressScale = 0.97;
  static const Duration press = Duration(milliseconds: 120);
  static const Curve pressCurve = Curves.easeOutCubic;

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration statusTransition = Duration(milliseconds: 560);
  static const Duration composerGlowLoop = Duration(seconds: 12);
  static const Duration composerGlowEnter = Duration(milliseconds: 700);
  static const Duration composerGlowExit = Duration(milliseconds: 500);
  static const double composerGlowEntryScale = 0.84;
  static const double composerGlowRestScale = 1.08;
  static const double composerGlowEntryTurns = -0.035;
  static const Duration aiLabelTransition = Duration(milliseconds: 400);
  static const Offset aiLabelOffset = Offset(0, 0.18);
  static const Duration statusPulse = Duration(milliseconds: 1500);
  static const Curve emphasized = Curves.easeOutCubic;

  static const Duration messageSend = Duration(milliseconds: 360);
  static const Offset messageSendOffset = Offset(0.12, 0.28);
  static const double messageSendScale = 0.96;
  static const double messageSendOpacity = 0.55;
  static const Curve messageSendCurve = Curves.easeOutCubic;
  static const Curve messageSendSpring = Curves.easeOutBack;
}
