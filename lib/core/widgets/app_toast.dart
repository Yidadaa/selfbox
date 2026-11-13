import 'package:flutter/widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_icons.dart';
import 'app_icon.dart';

abstract final class AppToast {
  static VoidCallback show(
    BuildContext context, {
    required String message,
    GlassToastType type = GlassToastType.success,
  }) => GlassToast.show(
    context,
    message: message,
    type: type,
    icon: AppIcon(switch (type) {
      GlassToastType.success => AppIcons.success,
      GlassToastType.error => AppIcons.error,
      GlassToastType.warning => AppIcons.warning,
      GlassToastType.info || GlassToastType.neutral => AppIcons.info,
    }),
  );
}
