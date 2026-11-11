import 'dart:math' as math;

abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 28;
  static const double xl = 36;
  static const double pill = 999;

  /// Below this an inner corner stops reading as curved on high-density screens.
  static const double minInner = 8;

  /// Concentric corners: nested shapes share the outer shape's optical center,
  /// so the inner radius shrinks by exactly the padding between them.
  static double concentric({required double outer, required double padding}) =>
      math.max(outer - padding, minInner);
}
