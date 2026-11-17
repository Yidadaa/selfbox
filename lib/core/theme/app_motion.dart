import 'package:flutter/widgets.dart';

abstract final class AppMotion {
  static const double pinCollapsedScale = 0.16;
  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;

  static AnimationStyle? style(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? AnimationStyle.noAnimation
      : null;

  static const double pressScale = 0.97;
  static const Duration press = Duration(milliseconds: 120);
  static const Curve pressCurve = Curves.easeOutCubic;

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration toastDisplay = Duration(seconds: 3);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration composerKeyboard = Duration(milliseconds: 280);
  static const Curve composerKeyboardCurve = Curves.easeInOutCubic;
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration statusTransition = Duration(milliseconds: 560);
  static const Offset assistantStageOffset = Offset(0, 0.08);
  static const Duration composerGlowEnter = Duration(milliseconds: 700);
  static const Duration composerGlowExit = Duration(milliseconds: 500);
  static const double composerGlowRestScale = 1.08;
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
