import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

class AppPageTransitions extends GlassPageTransitionsBuilder {
  const AppPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MediaQuery.disableAnimationsOf(context)
      ? child
      : super.buildTransitions(
          route,
          context,
          animation,
          secondaryAnimation,
          child,
        );
}
