import 'package:flutter/widgets.dart';

import 'app_dialog_tokens.dart';
import 'app_spacing.dart';

abstract final class AppPopoverTokens {
  static const width = 136.0;
  static const itemHeight = 44.0;
  static const radius = AppDialogTokens.radius - AppSpacing.md;

  static Color highlight(Brightness brightness) => switch (brightness) {
    Brightness.light => const Color(0x14787880),
    Brightness.dark => const Color(0x24787880),
  };
}
