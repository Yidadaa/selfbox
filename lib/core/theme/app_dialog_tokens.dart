import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Opaque confirmation dialogs keep the native Liquid alert's proportions.
abstract final class AppDialogTokens {
  static const double width = 320;
  static const double radius = 34;
  static const double labelSize = 17;
  static const double pickerHeight = 332;
  static const double pickerItemExtent = 44;

  static const EdgeInsets headerInsets = EdgeInsets.fromLTRB(
    AppSpacing.xxl,
    AppSpacing.xl,
    AppSpacing.xxl,
    AppSpacing.xxs,
  );
  static const EdgeInsets actionInsets = EdgeInsets.all(AppSpacing.md);
}
