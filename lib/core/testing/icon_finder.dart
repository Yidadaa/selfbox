import 'package:flutter_test/flutter_test.dart';

import '../theme/app_icons.dart';
import '../widgets/app_icon.dart';

Finder findAppIcon(AppIconData icon) => find.byWidgetPredicate(
  (widget) => widget is AppIcon && identical(widget.icon, icon),
  description: 'AppIcon using the expected Hugeicons glyph',
);
