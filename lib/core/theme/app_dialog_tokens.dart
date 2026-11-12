import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Dimensions shared by the app's opaque dialogs.
abstract final class AppDialogTokens {
  static const double width = 320;
  static const double radius = 34;
  static const double labelSize = 17;
  static const double pickerHeight = 332;
  static const double pickerItemExtent = 44;
  static const double modelSheetFraction = 0.58;

  static const EdgeInsets headerInsets = EdgeInsets.fromLTRB(
    AppSpacing.xxl,
    AppSpacing.xl,
    AppSpacing.xxl,
    AppSpacing.xxs,
  );
  static const EdgeInsets actionInsets = EdgeInsets.all(AppSpacing.md);
}
