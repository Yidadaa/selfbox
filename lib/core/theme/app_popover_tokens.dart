import 'package:flutter/painting.dart';

import 'app_glass_theme.dart';

abstract final class AppPopoverTokens {
  static const background = Color(0xFFFFFFFF);
  static final foreground = AppGlassTheme.light.foreground;
  static final destructive = AppGlassTheme.light.dialogDestructive;
  static const highlight = Color(0xFFE7EEF7);
  static const width = 224.0;
  static const shadow = BoxShadow(
    color: Color(0x300B142B),
    blurRadius: 40,
    spreadRadius: 2,
    offset: Offset(0, 12),
  );
}
