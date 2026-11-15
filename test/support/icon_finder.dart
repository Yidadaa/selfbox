import 'package:flutter_test/flutter_test.dart';
import 'package:selfbox/core/theme/app_icons.dart';
import 'package:selfbox/core/widgets/app_icon.dart';

Finder findAppIcon(AppIconData icon) => find.byWidgetPredicate(
  (widget) => widget is AppIcon && identical(widget.icon, icon),
  description: 'AppIcon using the expected Hugeicons glyph',
);
