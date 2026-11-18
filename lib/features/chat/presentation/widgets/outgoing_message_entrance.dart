import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:selfbox/core/theme/sdk_material.dart';

import '../../../../core/theme/app_motion.dart';

/// Reveals a newly persisted row while its height pushes older rows upward.
class OutgoingMessageEntrance extends HookWidget {
  const OutgoingMessageEntrance({
    required this.child,
    required this.onComplete,
    this.alignment = Alignment.bottomRight,
    this.offset = AppMotion.messageSendOffset,
    super.key,
  });

  final Widget child;
  final VoidCallback onComplete;
  final Alignment alignment;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: AppMotion.messageSend);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final completed = useRef(false);
    useEffect(() {
      void complete() {
        if (completed.value) return;
        completed.value = true;
        onComplete();
      }

      if (reduceMotion) {
        controller.value = 1;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) complete();
        });
      } else if (!completed.value) {
        unawaited(controller.forward().then((_) => complete()));
      }
      return null;
    }, [controller, reduceMotion]);

    final progress = controller.drive(
      CurveTween(curve: AppMotion.messageSendCurve),
    );
    final spring = controller.drive(
      CurveTween(curve: AppMotion.messageSendSpring),
    );
    return RepaintBoundary(
      child: SizeTransition(
        sizeFactor: progress,
        alignment: Alignment.bottomCenter,
        child: FadeTransition(
          opacity: Tween<double>(
            begin: AppMotion.messageSendOpacity,
            end: 1,
          ).animate(progress),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: offset,
              end: Offset.zero,
            ).animate(progress),
            child: ScaleTransition(
              alignment: alignment,
              scale: Tween<double>(
                begin: AppMotion.messageSendScale,
                end: 1,
              ).animate(spring),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
