import 'package:flutter/widgets.dart';

import '../theme/app_glass_theme.dart';

/// The canvas layer: a rich gradient for glass surfaces to refract against.
/// Light enters from the top-left, matching the highlight edge on glass.
class AppCanvas extends StatelessWidget {
  const AppCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.glass.canvasGradient,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
