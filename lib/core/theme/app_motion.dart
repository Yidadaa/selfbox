import 'package:flutter/animation.dart';

abstract final class AppMotion {
  static const double pressScale = 0.97;
  static const Duration press = Duration(milliseconds: 120);
  static const Curve pressCurve = Curves.easeOutCubic;

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
  static const Curve emphasized = Curves.easeOutCubic;
}
