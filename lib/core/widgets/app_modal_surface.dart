import 'package:selfbox/core/theme/sdk_material.dart';

import '../theme/app_dialog_tokens.dart';
import '../theme/app_glass_theme.dart';
import '../theme/app_motion.dart';
import '../theme/app_relief_theme.dart';

/// Shared opaque lighting and clipping for dialogs and bottom sheets.
class AppModalSurface extends StatelessWidget {
  const AppModalSurface({required this.shape, required this.child, super.key});

  final OutlinedBorder shape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final relief = AppReliefTheme.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        gradient: relief.surfaceGradient,
        shadows: relief.surfaceShadows,
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: ShapeDecoration(shape: shape.copyWith(side: relief.border)),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: child,
        ),
      ),
    );
  }
}

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
}) => showModalBottomSheet<T>(
  context: context,
  sheetAnimationStyle: AppMotion.style(context),
  isScrollControlled: isScrollControlled,
  useRootNavigator: useRootNavigator,
  backgroundColor: context.glass.bubbleOther,
  elevation: 0,
  shape: AppDialogTokens.sheetShape,
  clipBehavior: Clip.none,
  builder: (context) => AppModalSurface(
    shape: AppDialogTokens.sheetShape,
    child: builder(context),
  ),
);
