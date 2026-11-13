import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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
    useEffect(() {
      unawaited(controller.forward().then((_) => onComplete()));
      return null;
    }, [controller]);

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
