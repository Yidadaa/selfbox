import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app_radius.dart';

import 'app_spacing.dart';

/// Dimensions shared by the app's opaque dialogs.
abstract final class AppDialogTokens {
  static const double width = 320;
  static const double radius = 34;
  static const dialogShape = LiquidRoundedSuperellipse(borderRadius: radius);
  // The library delegates to this same Flutter border; only bottom corners differ.
  static const sheetShape = RoundedSuperellipseBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
  );
  static final actionShape = LiquidRoundedSuperellipse(
    borderRadius: AppRadius.concentric(outer: radius, padding: AppSpacing.md),
  );
  static const double labelSize = 17;
  static const double pickerHeight = 332;
  static const double pickerItemExtent = 44;
  static const double modelSheetFraction = 0.58;
  static const double avatarSheetFraction = 0.64;

  static const EdgeInsets headerInsets = EdgeInsets.fromLTRB(
    AppSpacing.xxl,
    AppSpacing.xl,
    AppSpacing.xxl,
    AppSpacing.xxs,
  );
  static const EdgeInsets actionInsets = EdgeInsets.all(AppSpacing.md);
}
