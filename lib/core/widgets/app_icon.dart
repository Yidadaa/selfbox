import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_icons.dart';

/// Keeps glyph metrics, inherited button colors and accessibility consistent.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    this.size,
    this.color,
    this.semanticLabel,
    super.key,
  });

  final AppIconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    excludeSemantics: true,
    child: HugeIcon(
      icon: icon,
      size: size,
      color: color,
      strokeWidth: AppIconTokens.strokeWidth,
    ),
  );
}
