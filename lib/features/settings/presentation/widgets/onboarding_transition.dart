import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/onboarding_tokens.dart';

class OnboardingTransition extends StatelessWidget {
  const OnboardingTransition({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedSize(
      duration: AppMotion.slow,
      curve: AppMotion.emphasized,
      child: AnimatedSwitcher(
        duration: AppMotion.slow,
        switchInCurve: AppMotion.emphasized,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.center,
          children: [
            for (final child in previous)
              ExcludeSemantics(child: IgnorePointer(child: child)),
            ?current,
          ],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: OnboardingTokens.entryOffset,
              end: Offset.zero,
            ).animate(animation),
            child: ScaleTransition(
              scale: Tween(
                begin: OnboardingTokens.entryScale,
                end: 1.0,
              ).animate(animation),
              child: child,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}
